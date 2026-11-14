--[[
    Living City (client): what you can do here

    A small panel on the right of the screen with the things this city has
    built that the game itself never tells you about: what the tool in your
    hands does here (the Arrest Baton, the hoover, the sprayer, the radio...),
    where you're standing (rebel ground, your own block...), who you are (a
    unit's kick...) and what this step of your quest wants. Nothing the game
    already teaches ("left click shoots"). The keys are your own bindings,
    looked up live, as the tips do.

    It sits under the quest tracker and above the tip cards, and gives way to
    both: when there's no room for all of it, the least useful part goes.
    Bright for a few seconds when what's in it changes, then faint.

    Other modules can add lines:
      LC_CL.AddContextHint(kind, key, text, when)
        kind  "weapon": key is the weapon's class ("tool:<mode>" for a tool gun mode)
              "zone": rebel, infest, home, combine, prison (where you are, lc_here)
              "faction": citizen, resistance, cp, vort, zombie, admin... (lcf_faction)
              "quest": the step's kind (hold, tail, escort, pickup, collect...), or "_any"
              "nearby": anything (its own name): what's around you right now, shown first
        text  keys in braces: {+use}, {+reload}, {+attack2}, {+duck}, {+walk},
              {gm_showspare1}, {+menu_context}, {kick} (a unit's kick), {quick} (F1), {quick2} (F2)
              (or a function(me, ctx) -> the text, or nil for no line: for names)
        when  optional function(me, ctx) -> true when the line applies
        style optional function(me, ctx) -> "bright" (stays bright while it applies) or
              "faint" (always faint); nil: as the rest of the panel
      LC_CL.SetContextTitle(kind, key, title)

    The Resistance Insider, beside a prisoner being marched to the cells: "Let <name> slip
    away: F2 > 7" (bright; faint "not now, you're being watched" while someone can see).

    C > Settings: "What you can do here (on the right)" (lc_context_show, 1).
]]

LC_CL = LC_CL or {}

local cvShow = CreateClientConVar("lc_context_show", "1", true, false, "The panel of what you can do here, on the right of the screen: 1 on, 0 off")

surface.CreateFont("LCCtxHead", { font = "Tahoma", size = 12, weight = 700 })
surface.CreateFont("LCCtxLine", { font = "Tahoma", size = 13, weight = 500 })

local W = 270
local ROW = 15
local MAX_LINES = 9      -- across every part of the panel
local MAX_PER_GROUP = 4
local BRIGHT_SECS = 6    -- bright this long after it changes, then faint
local FAINT = 0.6

local BG = Color(10, 12, 16, 165)
local HEAD = Color(150, 185, 215)
local INK = Color(225, 225, 220)
local KEY = Color(240, 200, 110)

------------------------------------------------------------------------
-- Keys, as the player has them bound
------------------------------------------------------------------------

local DEFAULT_KEYS = { ["+use"] = "E", ["+reload"] = "R", ["+attack"] = "MOUSE1", ["+attack2"] = "MOUSE2",
    ["+duck"] = "CTRL", ["+speed"] = "SHIFT", ["+walk"] = "ALT", ["+jump"] = "SPACE", ["+menu"] = "Q",
    gm_showhelp = "F1", gm_showteam = "F2", gm_showspare1 = "F3", gm_showspare2 = "F4", ["+menu_context"] = "C" }
local NICE = { MOUSE1 = "Left click", MOUSE2 = "Right click", MOUSE3 = "Middle click" }

function LC_CL.ContextKey(name)
    if name == "kick" then return LC_CL.KickKeyName and LC_CL.KickKeyName() or "G" end
    if name == "quick" then return LC_CL.QuickKeyName and LC_CL.QuickKeyName() or "F1" end
    if name == "quick2" then return LC_CL.QuickRoleKeyName and LC_CL.QuickRoleKeyName() or "F2" end
    local k = input and input.LookupBinding and input.LookupBinding(name)
    k = k and string.upper(k) or DEFAULT_KEYS[name]
    if not k then return nil end
    return NICE[k] or k
end

function LC_CL.ContextText(text)
    return (string.gsub(text or "", "{([%w_%+]+)}", function(n)
        local k = LC_CL.ContextKey(n)
        return k and ("[" .. k .. "]") or nil
    end))
end

------------------------------------------------------------------------
-- What there is to say
------------------------------------------------------------------------

LC_CL.ContextHints = LC_CL.ContextHints or { weapon = {}, zone = {}, faction = {}, quest = {} }
LC_CL.ContextHints.nearby = LC_CL.ContextHints.nearby or {}

local function Entry(kind, key)
    local list = LC_CL.ContextHints[kind]
    if not list then return nil end
    list[key] = list[key] or { lines = {} }
    return list[key]
end

function LC_CL.SetContextTitle(kind, key, title)
    local e = Entry(kind, key)
    if e then e.title = title end
end

function LC_CL.AddContextHint(kind, key, text, when, style)
    local e = Entry(kind, key)
    if not e or not text then return end
    e.lines[#e.lines + 1] = { t = text, when = when, style = style }
end

local function Unit(me) return me:GetNW2Bool("lc_unit", false) or me:GetNW2String("lcf_faction", "") == "cp" end
local function NotUnit(me) return not Unit(me) end
local function Fac(id) return function(me) return me:GetNW2String("lcf_faction", "") == id end end
local function Jailed(me) return me:GetNW2Float("lc_jail_until", 0) > CurTime() end

-- { title, line, line... }: a line is its text, or { text, when }
local DATA = {
    weapon = {
        weapon_lc_baton = { "Arrest Baton",
            { "{+use} on a citizen: they stop and wait, so you can search them", Unit },
            "{+reload} on someone: search them (or let a prisoner go)",
            "{+attack2} on someone: arrest them and send them to a cell",
            -- (the owner, 11 November: it sent you to the Unit tools window, which fills the screen; the quick menu does it)
            { "Cuff a player: look at them up close, then {quick2} > Cuff. An NPC: {+attack2} cuffs them", Unit },
            { "Cuffed: {quick2} > Drag along, or Walk them to the cells", Unit } },
        weapon_lc_hoover = { "Hoover",
            "Hold {+attack} on a dead growth: vacuum it up",
            "{+use} on an infestation control barrel: empty it",
            "{+attack2} with no barrel near: seal it in a bag" },
        weapon_lc_sprayer = { "Weedkiller sprayer",
            "Hold {+attack} on a weed or a glowing growth: spray it dead",
            "Runs on the weedkiller in your pockets ({gm_showspare1}): the job tops it up" },
        weapon_lc_radio = { "Radio transmitter",
            "While it's up, your chat and voice go out over the radio",
            "Only someone right beside you hears you directly",
            "{+attack}: call for backup",
            "{+attack2}: the Radio menu (HQ calls, jobs, switching frequency)",
            "{+reload}: put it away" },
        weapon_lc_multitool = { "Multitool",
            "{+attack} at a Combine door, a city screen, a data terminal or a shackled vortigaunt: hack it" },
        weapon_lc_grenades = { "Grenades",
            "{+reload}: switch what you throw (smoke, flashbang, gas...)" },
        weapon_lc_hands = { "Hands",
            "{+reload}: raise your fists, or draw what you had",
            "{+attack2} on an apartment door: rent it, or lock and unlock yours" },
        weapon_lc_blessing = { "The Blessing",
            "{+attack}: heal one person",
            "{+attack2}: a prayer for everyone near you",
            "{+reload}: preach" },
        weapon_lc_vort = { "Vortessence",
            "{+attack}: a bolt (it shorts out power banks, forcefields and turrets)",
            "{+attack2}: charge a vest, or mend another vortigaunt" },
        weapon_lc_microphone = { "Microphone",
            "{+attack}: go live on every loudspeaker and screen (a minute, once every fifteen)" },
        weapon_lc_posters = { "Poster roll",
            "{+attack}: hang the poster on the wall in front of you",
            "{+attack2}: take a poster down",
            "{+reload}: choose another poster" },
        weapon_lc_admin = { "Administrator's tablet",
            "{+attack} at someone: your bodyguard kills them",
            "{+attack2}: the office" },
        weapon_lc_rebelclip = { "The cell's clipboard",
            "{+attack}: the rules and the mood, as boxes to tick (number keys)",
            "What you set is written on the Resistance's notice board" },
        weapon_crowbar = { "Crowbar",
            "{+use} on junk (a wreck, pipes, a crate): pry out scrap. It's loud",
            { "A unit who sees it out makes you wanted (not on rebel ground)", NotUnit } },
        ["tool:livingcity_editor"] = { "Miscount Editor",
            "{+reload}: the next mode",
            "Every mode and setting: hold {+menu}, Tools > Miscount Editor" },
    },
    zone = {
        rebel = { "Rebel territory",
            { "The black market is open ({+menu_context} > Getting by), and the bins have better finds", Fac("citizen") },
            { "Make guns and ammunition here ({gm_showspare1})", Fac("resistance") },
            { "Fighters shout one warning, then open fire. Kills here win ground back", Unit } },
        infest = { "The infestation",
            { "Kills here push the infestation back", Unit } },
        home = { "Your block",
            "Make things here ({gm_showspare1})",
            "Your stash: {+menu_context} > Getting by",
            "When a curfew starts, be here" },
        combine = { "Combine only",
            { "Leave before the countdown runs out, or you're wanted", NotUnit } },
        prison = { "The prison",
            { "A lockpick from a visitor opens your cell: {+menu_context} > This door > Pick the lock", Jailed } },
    },
    faction = {
        cp = { "Civil Protection",
            "{kick}: kick (a door in, someone back)",
            "{quick2}: voice lines, unit tools, backup, BOLO, your 10-20" },
        resistance = { "Resistance",
            "{quick2}: gear up, or plain clothes (units leave plain clothes alone)" },
        citizen = { "Citizen",
            "Stopped by a unit? {quick} > Put my hands up" },
    },
    quest = {
        hold = { "This step",
            { "Crouch ({+duck}) in the marked spot until the bar fills", function(_, ctx) return ctx.quest and ctx.quest.crouch end },
            { "Stay in the marked spot until the bar fills", function(_, ctx) return not (ctx.quest and ctx.quest.crouch) end } },
        tail = { "This step",
            "Keep back and out of their sight: the bar fills while they see you",
            "Crouch ({+duck}) to creep up behind units" },
        escort = { "This step",
            "They follow you: keep them close",
            { "Walk ({+walk}): they can't keep up at a run", function(_, ctx) return ctx.quest and ctx.quest.walk end } },
        pickup = { "This step", "{+use} on the marked item to take it" },
        collect = { "This step", "{+use} on each marked item" },
        _any = { "This step",
            { "Follow the chevrons on the ground (hide them: {+menu_context} > Settings)", function() return LC_CL.TrailActive and LC_CL.TrailActive() end } },
    },
}

for kind, list in pairs(DATA) do
    for key, def in pairs(list) do
        LC_CL.SetContextTitle(kind, key, def[1])
        for i = 2, #def do
            local l = def[i]
            if type(l) == "table" then LC_CL.AddContextHint(kind, key, l[1], l[2]) else LC_CL.AddContextHint(kind, key, l) end
        end
    end
end

-- The Resistance Insider, beside a prisoner being marched to the cells (cl_livingcity_actions.lua,
-- sv_livingcity_insider.lua): there as long as the prisoner is within reach.
LC_CL.SetContextTitle("nearby", "insider_slip", "Inside")
LC_CL.AddContextHint("nearby", "insider_slip", function(me)
    if not LC_CL.InsiderSlipNow then return nil end
    local t, why = LC_CL.InsiderSlipNow(me)
    if not t then return nil end
    local name = LC_CL.ICName and LC_CL.ICName(t) or "them"
    local whyNot = LC_CL.InsiderSlipWhyNot and LC_CL.InsiderSlipWhyNot(why)
    if whyNot then return "Let " .. name .. " slip away: " .. whyNot end
    local n = LC_CL.QuickSlot and LC_CL.QuickSlot("letslip")
    return "Let " .. name .. " slip away: {quick2}" .. (n and (" > " .. n) or "")
end, nil, function(me)
    if not LC_CL.InsiderSlipNow then return "faint" end
    local t, why = LC_CL.InsiderSlipNow(me)
    return (t and why == "") and "bright" or "faint"
end)

-- Cuffed, caged, beside a prisoner or the evidence locker (the owner, 12 November: "please add this, and other
-- similar new options, to the context HUD popup on the right"): sv_livingcity_patdown.lua, sv_livingcity_evidence.lua.
local function Tied(me) return me:GetNW2Bool("lc_tied", false) end
local function Caged(me) return IsValid(me:GetNW2Entity("lc_rebel_cage_in")) end
local function LooksAt(me, range)
    local tr = me.GetEyeTrace and me:GetEyeTrace()
    local e = tr and tr.Entity
    if IsValid(e) and e:GetPos():DistToSqr(me:GetPos()) < (range or 130) ^ 2 then return e end
    return nil
end
LC_CL.SetContextTitle("nearby", "cuffed", "Cuffed")
LC_CL.AddContextHint("nearby", "cuffed", "{quick} > Work at the cuffs: slow, and only when no captor is watching", Tied)
LC_CL.AddContextHint("nearby", "cuffed", "{quick} > Pick the cuffs: quicker, with a lockpick. Seen, they take it", Tied)
LC_CL.SetContextTitle("nearby", "caged", "In the cage")
LC_CL.AddContextHint("nearby", "caged", "They let you out after a few minutes", Caged)
LC_CL.AddContextHint("nearby", "caged", "Hands free and a lockpick: {quick} > Pick the cage's padlock",
    function(me) return Caged(me) and not Tied(me) end)
LC_CL.SetContextTitle("nearby", "prisoner", "Your prisoner")
local function Prisoner(me)
    local e = LooksAt(me, 130)
    return e ~= nil and e:IsPlayer() and e:GetNW2Bool("lc_tied", false) and not Tied(me)
end
LC_CL.AddContextHint("nearby", "prisoner", "{quick} > Pat them down: weapons, radios and tools out of their pockets", Prisoner)
LC_CL.AddContextHint("nearby", "prisoner", "{quick} > Drag them along, or uncuff them", Prisoner)
LC_CL.SetContextTitle("nearby", "inchair", "In the chair")
LC_CL.AddContextHint("nearby", "inchair", "When they ask, answer with the number keys: the truth, a lie, or nothing",
    function(me) return IsValid(me:GetNW2Entity("lc_chair_in")) end)
LC_CL.SetContextTitle("nearby", "evlocker", "Evidence locker")
local function AtLocker(me)
    local e = LooksAt(me, 160)
    return e ~= nil and e:GetNW2Bool("lc_evlocker", false)
end
LC_CL.AddContextHint("nearby", "evlocker", "{+use}: open it", function(me) return AtLocker(me) and (me:GetNW2String("lcf_faction", "") == "cp") end)
LC_CL.AddContextHint("nearby", "evlocker", "{+use}: pick the lock (quiet, unless a unit sees) or pry it with a crowbar (loud)",
    function(me) return AtLocker(me) and me:GetNW2String("lcf_faction", "") ~= "cp" end)

------------------------------------------------------------------------
-- What applies now
------------------------------------------------------------------------

local function Collect(me, ctx, kind, key, out, budget)
    local e = key and LC_CL.ContextHints[kind] and LC_CL.ContextHints[kind][key]
    if not e then return end
    local group
    for _, l in ipairs(e.lines) do
        if budget.left <= 0 then break end
        local ok, yes = true, true
        if l.when then ok, yes = pcall(l.when, me, ctx) end
        local text = l.t
        if ok and yes and type(text) == "function" then
            ok, text = pcall(text, me, ctx)
            yes = ok and type(text) == "string" and text ~= ""
        end
        if ok and yes then
            if not group then
                -- (one group per title: the quest's "_any" lines join its step's)
                for _, g in ipairs(out) do if g.title == e.title and g.kind == kind then group = g end end
                if not group then
                    group = { title = e.title or "", kind = kind, lines = {} }
                    out[#out + 1] = group
                end
            end
            if #group.lines < MAX_PER_GROUP then
                group.lines[#group.lines + 1] = LC_CL.ContextText(text)
                if l.style then
                    local okS, st = pcall(l.style, me, ctx)
                    if okS and (st == "bright" or st == "faint") then
                        group.style = group.style or {}
                        group.style[#group.lines] = st
                    end
                end
                budget.left = budget.left - 1
            end
        end
    end
end

-- The panel's parts, most useful first: the tool in your hands, your quest's
-- step, where you are, who you are. { { title, kind, lines = { text... } }... }
function LC_CL.ContextGroups(me)
    me = me or LocalPlayer()
    if not IsValid(me) then return {} end
    local ctx = { faction = me:GetNW2String("lcf_faction", ""), zone = me:GetNW2String("lc_here", "") }
    local w = me.GetActiveWeapon and me:GetActiveWeapon()
    if IsValid(w) and w.GetClass then
        ctx.weapon = w:GetClass()
        if ctx.weapon == "gmod_tool" and w.GetMode then
            local ok, mode = pcall(w.GetMode, w)
            if ok and mode then ctx.weapon = "tool:" .. tostring(mode) end
        end
    end
    local q = LC_CL.QuestState and LC_CL.QuestState()
    if q and q.active then ctx.quest = q end
    local out, budget = {}, { left = MAX_LINES }
    -- what's around you right now first: it won't be there for long
    local near = {}
    for key in pairs(LC_CL.ContextHints.nearby) do near[#near + 1] = key end
    table.sort(near)
    for _, key in ipairs(near) do Collect(me, ctx, "nearby", key, out, budget) end
    Collect(me, ctx, "weapon", ctx.weapon, out, budget)
    if ctx.quest then
        Collect(me, ctx, "quest", ctx.quest.kind, out, budget)
        Collect(me, ctx, "quest", "_any", out, budget)
    end
    Collect(me, ctx, "zone", ctx.zone ~= "" and ctx.zone or nil, out, budget)
    Collect(me, ctx, "faction", ctx.faction, out, budget)
    return out
end

------------------------------------------------------------------------
-- On screen
------------------------------------------------------------------------

local function Wrap(text, width)
    surface.SetFont("LCCtxLine")
    local lines, line = {}, ""
    for word in string.gmatch(text, "%S+") do
        local try = line == "" and word or (line .. " " .. word)
        if line ~= "" and surface.GetTextSize(try) > width then
            lines[#lines + 1] = line
            line = word
        else
            line = try
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

-- Where it may go: under the clock, the quest tracker and the job games'
-- panel, and above the tip cards (whichever were drawn a moment ago).
function LC_CL.ContextRoom()
    local now = CurTime()
    local top = math.max(80, math.floor(ScrH() * 0.38))
    if LC_CL.QuestTrackerAt and now - LC_CL.QuestTrackerAt < 0.25 then top = math.max(top, LC_CL.QuestTrackerBottom + 10) end
    if LC_CL.JobGameAt and now - LC_CL.JobGameAt < 0.25 then top = math.max(top, LC_CL.JobGameBottom + 10) end
    local bottom = ScrH() - 180 -- (the tip cards' bottom edge is at ScrH() - 170, the grenades' list under it)
    if LC_CL.HintAt and now - LC_CL.HintAt < 0.25 then bottom = math.min(bottom, LC_CL.HintTop - 10) end
    return top, bottom
end

local cache = { at = -1, groups = {}, sig = "", changed = 0 }

function LC_CL.ContextShown()
    return cvShow:GetBool()
end

-- Made once, not every frame: the faint copy of each colour, a key's width, a title in capitals.
local faded = {}
local function Faded(c)
    local f = faded[c]
    if not f then f = Color(c.r, c.g, c.b, (c.a or 255) * FAINT) faded[c] = f end
    return f
end
local keyW = {}
local function KeyWidth(k)
    local kw = keyW[k]
    if not kw then
        surface.SetFont("LCCtxLine")
        kw = surface.GetTextSize(k)
        keyW[k] = kw
    end
    return kw
end
local upper, upperN = {}, 0
local function Upper(t)
    local u = upper[t]
    if not u then
        if upperN > 200 then upper, upperN = {}, 0 end -- (titles are few; never let it grow)
        u = string.upper(t)
        upper[t], upperN = u, upperN + 1
    end
    return u
end

hook.Add("HUDPaint", "LivingCityContext", function()
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() or not cvShow:GetBool() then return end
    if LC_CL.DreamQuietHUD and LC_CL.DreamQuietHUD(me) then return end
    local now = CurTime()
    if now - cache.at > 0.25 or now < cache.at then
        cache.at = now
        local groups = LC_CL.ContextGroups(me)
        local parts = {}
        for _, g in ipairs(groups) do
            parts[#parts + 1] = g.title
            for i, l in ipairs(g.lines) do parts[#parts + 1] = (g.style and g.style[i] or "") .. l end
        end
        local sig = table.concat(parts, "\n")
        if sig ~= cache.sig then
            cache.sig, cache.changed = sig, now
            -- wrapped once, when it changes
            for _, g in ipairs(groups) do
                g.rows, g.rowStyle = {}, {}
                for i, l in ipairs(g.lines) do
                    for _, r in ipairs(Wrap(l, W - 18)) do
                        g.rows[#g.rows + 1] = r
                        g.rowStyle[#g.rows] = g.style and g.style[i] or nil
                    end
                end
            end
            cache.groups = groups
        end
    end
    local groups = cache.groups
    if #groups == 0 then return end

    -- what fits: whole parts, most useful first
    local top, bottom = LC_CL.ContextRoom()
    local shown, h = {}, 8
    for _, g in ipairs(groups) do
        local gh = ROW + #(g.rows or {}) * ROW + 4
        if top + h + gh > bottom then break end
        shown[#shown + 1] = g
        h = h + gh
    end
    LC_CL.ContextDrawn = shown
    if #shown == 0 then return end

    local faint = not (now - cache.changed < BRIGHT_SECS)
    local function A(c) return faint and Faded(c) or c end
    local x, y = ScrW() - W - 20, top
    draw.RoundedBox(4, x, y, W, h, A(BG))
    local ly = y + 5
    for _, g in ipairs(shown) do
        draw.SimpleText(Upper(g.title), "LCCtxHead", x + 9, ly, A(HEAD))
        ly = ly + ROW
        for i, r in ipairs(g.rows or {}) do
            -- a line can ask to stay bright (while it applies), or to be faint
            local st = g.rowStyle and g.rowStyle[i]
            local function B(c) if st == "bright" then return c elseif st == "faint" then return Faded(c) end return A(c) end
            -- the keys stand out: a row that starts with one has it in amber
            local k, rest = string.match(r, "^(%b[])(.*)$")
            if k then
                draw.SimpleText(k, "LCCtxLine", x + 9, ly, B(KEY))
                local kw = KeyWidth(k)
                draw.SimpleText(rest, "LCCtxLine", x + 9 + kw, ly, B(INK))
            else
                draw.SimpleText(r, "LCCtxLine", x + 9, ly, B(INK))
            end
            ly = ly + ROW
        end
        ly = ly + 4
    end
end)
