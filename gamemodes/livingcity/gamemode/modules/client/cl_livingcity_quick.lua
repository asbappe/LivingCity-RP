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
           The Resistance's man inside, beside a prisoner being marched to the cells: 7
           lets them slip (greyed while someone can see).
           Later on 7 November (the owner): the Insider's Inside >, the Resistance's Freq 7 >,
           a citizen's Me >, My sentence in a cell, the Administrator's tablet, laws, dream,
           guards and order of arrest, a Division Leader's Call a sweep >. What's greyed, and
           why, comes from the server (lc_quick_info, sv_livingcity_quickmore.lua).

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

-- Out of character, on F1's main page (the owner, 10 November: "F1 > 6 > Out of character > 1. Nearby or
-- 2. Server-wide")
local function OOCPage()
    return { title = "OUT OF CHARACTER", items = {
        Item("Nearby...", function() Say("Out of character, nearby", "Not your character speaking, to the people near you", "/looc ") end),
        Item("Server-wide...", function() Say("Out of character, server-wide", "Not your character speaking, to the whole server", "// ") end),
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
-- More on F2 (the owner, later on 7 November). What greys out comes from the server
-- (sv_livingcity_quickmore.lua): sent with F2, and every two seconds while it's open.
------------------------------------------------------------------------

LC_CL.QuickInfo = LC_CL.QuickInfo or {}
local function AskInfo() if net and net.Start then net.Start("lc_quick_info") net.SendToServer() end end
net.Receive("lc_quick_info", function()
    local t = util.JSONToTable(net.ReadString() or "")
    LC_CL.QuickInfo = istable(t) and t or {}
    LC_CL.QuickInfoAt = CurTime()
    if LC_CL.QuickRebuild then LC_CL.QuickRebuild() end
end)
local function Info(k) return (LC_CL.QuickInfo or {})[k] or {} end
-- "  (squad 2 of 3)": how many you lead and may lead now (the owner, 9 November: squads shrink as more players join a side)
local function SquadTag()
    local me = LocalPlayer()
    if not IsValid(me) then return "" end
    local max = me:GetNW2Int("lc_squad_max", 0)
    if max <= 0 then return "" end
    return string.format("  (squad %d of %d)", me:GetNW2Int("lc_squad_n", 0), max)
end
local COMBINE = { cp = true, admin = true }
-- one of F2's own actions (sv_livingcity_quickmore.lua)
local function QM(cmd, arg, target)
    net.Start("lc_quickmore")
    net.WriteString(cmd)
    net.WriteString(arg or "")
    net.WriteEntity(IsValid(target) and target or NULL)
    net.SendToServer()
end
local function AdminDo(what, arg)
    net.Start("lc_admin_do")
    net.WriteString(what)
    net.WriteString(arg or "")
    net.WriteEntity(NULL)
    net.SendToServer()
end
-- "in 40s", "in 3m": nil when it's open now
local function Later(secs)
    secs = tonumber(secs) or 0
    if secs <= 0 then return nil end
    return secs < 90 and ("in " .. math.ceil(secs) .. "s") or ("in " .. math.ceil(secs / 60) .. "m")
end
-- an entry, greyed with why when `why` is given (picking a greyed one does nothing)
local function Can(label, run, why)
    local it = Item(label .. (why and ("  (" .. why .. ")") or ""), run)
    it.disabled = why ~= nil
    return it
end
local function Looking(me, far)
    local tr = me:GetEyeTrace()
    local e = tr and tr.Entity
    if IsValid(e) and e:IsPlayer() and e ~= me and e:GetPos():DistToSqr(me:GetPos()) < far * far then return e end
    return nil
end

-- The Insider: the same as C > Civil Protection > Inside, each greyed with why not now.
local function InsidePage()
    local me = LocalPlayer()
    local ins = Info("ins")
    local wait = ins.wait or {}
    local seen = ins.watched and "watched" or nil
    local shop = ins.commissary == false and "Commissary only" or nil
    local weed = ins.weedkiller == false and "no weedkiller" or nil
    local items = {
        Can("Tip off Freq 7...", function() Ask("Tip off Freq 7", "What do you tell the Resistance? (The next planned sweep, if any, goes with it.)", "tipoff") end, seen or Later(wait.tip)),
        Can("Lose a wanted person's record...", function() Ask("Lose a record", "Whose record goes missing? (Their name.)", "loserecord") end, seen or (ins.wanted == 0 and "nobody's wanted" or nil)),
        Can("Supplies for a dead drop", function() Send("skim") end, seen or shop or Later(wait.skim)),
        Can("Copy the city's records", function() Send("copyrecords") end, seen or Later(wait.copy)),
        Can("Foul the mask filters", function() Send("foulfilters") end, seen or shop or weed or Later(wait.foul)),
        Can("Spike the station's food", function() Send("spikefood") end, seen or shop or weed or Later(wait.spike)),
    }
    local slipT, slipWhy = nil, nil
    if LC_CL.InsiderSlipNow then slipT, slipWhy = LC_CL.InsiderSlipNow(me) end
    if slipT then items[#items + 1] = Can("Let " .. Name(slipT) .. " slip away", function() Send("letslip") end, (slipWhy == "watched" and "watched") or (slipWhy == "soon" and "not yet") or nil) end
    local who = Looking(me, 160)
    items[#items + 1] = who and Can("Reveal myself to " .. Name(who), function() Send("reveal") end) or Can("Reveal myself", function() end, "look at someone close")
    return { title = "INSIDE (ONLY YOU SEE THIS)", items = items, empty = { [9] = ins.watched and (ins.watched .. " Slip away first.") or nil } }
end

-- The Resistance's band: in the spirit of a unit's dispatch, but nobody gives orders.
local function Freq7Page()
    local r = Info("reb")
    return { title = "FREQ 7", items = {
        Can("Message on Freq 7...", function() Ask("Freq 7", "What do you say on Freq 7?", "r") end, r.tx == false and "no transmitter" or nil),
        Can("Call for backup" .. SquadTag(), function() QM("rbackup") end, (r.radio == false and "no Freq 7 radio") or Later(r.backup)),
        Can("Send my position", function() QM("rpos") end, Later(r.pos)),
        Item("Guide me to the nearest rebel ground", function() QM("guide", "rebel") end),
        Item("Guide me to the nearest lab", function() QM("guide", "lab") end),
    } }
end

-- A citizen's own: work, rations, home, standing (each marks the way, and says the rest).
local function MePage()
    local me = LocalPlayer()
    local m = Info("me")
    local work = "Find work"
    if m.work == "intake" or me:GetNW2Bool("lc_unreg", false) then work = "Find work: Civil Intake first"
    elseif m.work == "job" then work = "My work: " .. tostring(m.job or "my job")
    elseif m.work == "labor" then work = "Find work: Labor Assignment"
    elseif m.work == "board" then work = "Find work: the job board (F4)" end
    local rations = "My rations"
    if m.ready then rations = "My rations: ready now"
    elseif (tonumber(m.ration) or 0) > 0 then rations = "My rations: next in " .. math.ceil(m.ration / 60) .. " min" end
    if m.cards then rations = rations .. ", " .. m.cards .. " card" .. (m.cards == 1 and "" or "s") end
    local home = "My home and rent"
    if m.home == "apartment" then home = string.format("My home: apartment, %dh %02dm paid", math.floor((m.left or 0) / 3600), math.floor((m.left or 0) % 3600 / 60))
    elseif m.home == "block" then home = "My home: " .. tostring(m.block or "my block")
    elseif m.home == "none" then home = "Find a home (Housing Allocation)" end
    local wanted = m.wanted or me:GetNW2Float("lc_wanted_until", 0) > CurTime()
    local standing = "My standing: " .. tostring(m.standing or me:GetNW2Int("lce_standing", 0)) .. (wanted and ", WANTED" or "")
    local rows = {}
    if m.next then rows[6] = string.format("Next: %s at %d.", tostring(m.nextWhat or ""), m.next) end
    return { title = "ME", items = {
        Item(work, function() if m.work == "board" then Hub("jobs") else QM("work") end end),
        Item(rations, function() QM("rations") end),
        Item(home, function() QM("home") end),
        Item(standing, function() QM("standing") end),
    }, empty = rows }
end

-- The Administrator's two Elites. How close they follow, and what they do when there's trouble,
-- are her standing orders (the owner, 8 November): given any time, the one in force marked (now).
local GUARD_DISTS = { { "close", "Close" }, { "medium", "Medium" }, { "far", "Far" } }
local GUARD_MODES = {
    { "always", "As they always have", "As always" },
    { "stay", "Stay with me (shoot, but keep beside me)", "Stay with me" },
    { "between", "Stand between us (cover me from threats)", "Stand between us" },
    { "holdfire", "Hold fire unless fired on", "Hold fire" },
}
local function GuardChoicePage(title, list, key, default)
    return function()
        local cur = Info("adm")[key] or default
        local items = {}
        for _, c in ipairs(list) do
            items[#items + 1] = Item(c[2] .. (cur == c[1] and "  (now)" or ""), function() QM("guards", c[1]) end)
        end
        return { title = title, items = items }
    end
end
local function GuardsPage()
    local a = Info("adm")
    local none = a.guards == 0 and "no guards now" or nil
    local dist, mode = "Medium", "As always"
    for _, c in ipairs(GUARD_DISTS) do if c[1] == (a.dist or "medium") then dist = c[2] end end
    for _, c in ipairs(GUARD_MODES) do if c[1] == (a.mode or "always") then mode = c[3] end end
    return { title = "YOUR GUARDS", items = {
        Can("Follow me" .. ((a.hold == false and (a.guards or 0) > 0) and "  (now)" or ""), function() QM("guards", "follow") end, none),
        Can("Hold here" .. (a.hold and "  (holding)" or ""), function() QM("guards", "hold") end, none),
        Page("Follow distance: " .. dist, GuardChoicePage("FOLLOW DISTANCE", GUARD_DISTS, "dist", "medium")),
        Page("When there's trouble: " .. mode, GuardChoicePage("WHEN THERE'S TROUBLE", GUARD_MODES, "mode", "always")),
    } }
end

-- Tonight's dream, as the tablet has it: she chooses only a kind, now and then (sv_livingcity_dreamplan.lua).
local function DreamPage()
    local d = Info("adm").dream
    if not d then return { title = "TONIGHT'S DREAM", items = {}, empty = { "No word from the office yet: try again in a moment." } } end
    if not d.ready then return { title = "TONIGHT'S DREAM", items = {}, empty = { d.why or "The city can't dream yet." } } end
    local pl = d.plan or {}
    local items, notes = {}, {}
    if d.busy then notes[#notes + 1] = "The city is dreaming right now." end
    if pl.feel then notes[#notes + 1] = pl.feel end
    if pl.chosen then
        notes[#notes + 1] = "Chosen for tonight: " .. (pl.chosen == "nightmare" and "a Nightmare" or "a propaganda dream") .. ". You'll be in it."
        items[#items + 1] = Item("Take back tonight's choice", function() AdminDo("dream", "cancel") end)
    elseif pl.canPick then
        items[#items + 1] = Item("A Nightmare tonight (a punishment)", function() AdminDo("dream", "nightmare") end)
        items[#items + 1] = Item("A propaganda dream tonight", function() AdminDo("dream", "propaganda") end)
    else
        notes[#notes + 1] = pl.why or "You can't choose tonight's dream."
    end
    local skip = pl.skip ~= false
    items[#items + 1] = Item(skip and "Dreams I didn't choose: skipping (join them)" or "Dreams I didn't choose: joining (skip them)", function() AdminDo("dream", skip and "join" or "skip") end)
    notes[#notes + 1] = string.format("You choose a kind, once every %d nights; the city picks which, and the nights between are Happy or Neutral.", pl.every or 3)
    local rows = {}
    for i, n in ipairs(notes) do if #items + 1 + i <= 9 then rows[#items + 1 + i] = n end end
    return { title = "TONIGHT'S DREAM", items = items, empty = rows }
end

-- A senior unit's call: the city's own sweep and raid, when the pacing allows.
local function SweepPage()
    local s = Info("sweep")
    local rows = {}
    if s.sweep and s.raid == s.sweep then rows[4] = s.sweep
    else
        if s.sweep then rows[4] = "Sweep: " .. s.sweep end
        if s.raid then rows[5] = "Raid: " .. s.raid end
    end
    return { title = "CALL A SWEEP", items = {
        Can("Contraband sweep (inspections)", function() QM("sweep", "sweep") end, s.sweep and "not now" or nil),
        Can("Block raid (a housing block)", function() QM("sweep", "raid") end, s.raid and "not now" or nil),
    }, empty = rows }
end

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
        Page("Out of character", OOCPage),
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
    local items, usual, late = {}, {}, {}
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
        Add(Item("Call for backup" .. SquadTag(), function() Send("backup") end))
        Add(Item("Issue a BOLO...", function() Ask("BOLO", "What should Civil Protection units look out for?", "bolo") end))
        Add(Item("Send my 10-20", function() Send("10-20") end))
        -- the Resistance's man inside, beside a prisoner being marched to the cells (sv_livingcity_insider.lua):
        -- right after the six, only while it's there; greyed while someone can see
        local slipT, slipWhy = nil, nil
        if LC_CL.InsiderSlipNow then slipT, slipWhy = LC_CL.InsiderSlipNow(me) end
        if slipT then
            local whyNot = LC_CL.InsiderSlipWhyNot and LC_CL.InsiderSlipWhyNot(slipWhy)
            local slip = Item("Let " .. Name(slipT) .. " slip away" .. (whyNot and (" (" .. (slipWhy == "watched" and "someone can see you" or "not yet") .. ")") or ""),
                function() Send("letslip") end)
            slip.id, slip.disabled = "letslip", whyNot ~= nil
            Add(slip)
        end
        -- the Insider's own page, right after (the owner, later on 7 November)
        if LC_CL.Insider then
            local inside = Page("Inside", InsidePage)
            inside.id = "inside"
            Add(inside)
        end
        -- Division Leader and up: the city's sweep or raid, on order (after what's in front of you)
        if f == "cp" and me:GetNW2Int("lcf_rank", 1) >= 3 then
            local sw = Page("Call a sweep", SweepPage)
            sw.id = "sweep"
            late[#late + 1] = sw
        end
        usual = { Item("My directives (F4)", function() Hub("jobs") end), Item("Records terminal", function() Send("records") end) }
    elseif rebel then
        title, accent = "RESISTANCE", ACCENT.resistance
        local plain = me:GetNW2String("lcd_disguise", "") ~= ""
        Add(Item(plain and "Gear up (Resistance clothes)" or "Change into plain clothes", function() Send(plain and "gearup" or "plain") end))
        Add(Item("Black market", function() Send("market") end))
        Add(Page("Resistance", ResistancePage))
        if me:GetNW2Int("lc_squad_n", 0) > 0 then Add(Page("Squad orders", SquadPage)) end
        local band = Page("Freq 7", Freq7Page)
        band.id = "freq7"
        Add(band)
    elseif f == "admin" then
        -- only the Administrator sets sociostability (the owner, 7 November)
        Add(Page("Sociostability", SocioPage))
        Add(Item("Broadcast to the whole city...", function() Ask("Broadcast", "What does the city hear?", "broadcast") end))
        if #(LC_CL.Manpower or {}) > 0 then Add(Page("Combine manpower", ManpowerPage)) end
        -- (the owner, later on 7 November) the tablet, the laws, tonight's dream, the guards, an order of arrest
        Add(Item("Open my tablet (the office)", function() QM("office") end))
        Add(Item("The city's laws", function() Send("laws") end))
        Add(Page("Tonight's dream", DreamPage))
        Add(Page("Command the guards", GuardsPage))
        local t = Looking(me, 1500)
        if t and not t:IsAdmin() and not t:GetNW2Bool("lc_unit", false) and not COMBINE[t:GetNW2String("lcf_faction", "")] then
            local wanted = t:GetNW2Float("lc_wanted_until", 0) > CurTime()
            local arrest = Can("Order " .. Name(t) .. "'s arrest", function() QM("arrest", "", t) end, (wanted and "already wanted") or Later(Info("adm").arrest))
            arrest.id = "arrest"
            Add(arrest)
        end
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
    -- a citizen's own (the owner, later on 7 November): work, rations, home, standing
    if f == "citizen" or f == "" then
        local mine = Page("Me: work, rations, home, standing", MePage)
        mine.id = "me"
        Add(mine)
    end
    -- in a cell: what you're in for, and how long is left
    local jail = me:GetNW2Float("lc_jail_until", 0) - CurTime()
    if jail > 0 then
        local sentence = Item(string.format("My sentence: %d:%02d left", math.floor(jail / 60), math.floor(jail % 60)), function() QM("sentence") end)
        sentence.id = "sentence"
        Add(sentence)
    end
    -- staff
    if me:IsAdmin() then usual[#usual + 1] = Page("Staff", StaffPage) end
    -- then what only your side does to what's in front of you, then your usual ones
    for _, it in ipairs(Context(me, unit, rebel)) do if it.role then Add(it) end end
    for _, it in ipairs(late) do Add(it) end
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
    open = { page = LC_CL.QuickRoleRoot(), stack = {}, last = CurTime(), kind = "role", askAt = CurTime() + 2 }
    open.page.rebuild = LC_CL.QuickRoleRoot
    if CurTime() - (LC_CL.QuickInfoAt or -99) > 1 then AskInfo() end
end

-- New word from the server (what's greyed, and why): F2's page as it is now, in place.
function LC_CL.QuickRebuild()
    if not open or open.kind ~= "role" or not open.page.rebuild then return end
    local ok, page = pcall(open.page.rebuild)
    if ok and istable(page) then
        page.rebuild = open.page.rebuild
        page.accent = page.accent or open.page.accent
        open.page = page
    end
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
    if not it or it.disabled then return end
    if it.page then
        local accent = open.page.accent
        table.insert(open.stack, open.page)
        open.page = it.page()
        open.page.accent = open.page.accent or accent
        open.page.rebuild = it.page
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
    -- F2 stays up to date while it's open (what's greyed, and why)
    if open.kind == "role" and CurTime() >= (open.askAt or 0) then
        open.askAt = CurTime() + 2
        AskInfo()
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
            local col = it.disabled and DIM or (it.ctx and CONTEXT or INK)
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
