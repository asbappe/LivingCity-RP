--[[
    Living City (client): the actions menu (the full menu)

    C (the context menu key; in build mode it's still the build menu), or 9
    on the quick menu (F1, cl_livingcity_quick.lua).
    Everything you can do, for who you are and what you're looking at, so no
    chat command ever has to be remembered: every one of them is in here
    somewhere (the client smoke test checks), and chat commands still work as
    shortcuts. At the top: the guide, your pockets, board and factions, the
    tips you've had (to read again), and for units their Unit tools window.

      the person, body, door, machine in front of you
      Me          hands, holster, poses and gestures, papers, characters, name and description
      Talk        say your name to everyone near, yell, whisper, /me, /it, dice, OOC, radio
      Getting by  stash, Commissary, black market, writing, fishing, salvage, escorts
      Home        your block and apartment: lock, keys, giving it up
      The city    time and weather, who holds the city, the laws, broadcasts
      Civil Protection / Resistance, for those in them
      Settings    camera sway, third person while posing, tips
      Help        ask staff; the staff panel and admin tools for staff

    Also here: the interrogation choice, on screen.
]]

LC_CL = LC_CL or {}

local function Send(cmd, rest, target)
    net.Start("lc_action")
    net.WriteString(cmd)
    net.WriteString(rest or "")
    net.WriteEntity(IsValid(target) and target or NULL)
    net.SendToServer()
end
LC_CL.SendAction = Send

local function Ask(title, prompt, cmd, default)
    Derma_StringRequest(title, prompt, default or "", function(text) if string.Trim(text) ~= "" then Send(cmd, text) end end)
end
LC_CL.AskAction = Ask

-- Talking: the same as typing it in chat (the chat prefixes do the work).
local function Say(title, prompt, prefix)
    Derma_StringRequest(title, prompt, "", function(text)
        text = string.Trim(text or "")
        if text ~= "" then RunConsoleCommand("say", prefix .. text) end
    end)
end

-- Am I the Resistance's man inside? Told to me alone (sv_livingcity_insider.lua).
net.Receive("lc_insider", function() LC_CL.Insider = net.ReadBool() end)

local function Title(s) return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2) end

-- Who someone is, to you: a unit's designation, a name you know, or what they look like.
function LC_CL.ICName(ply)
    if not IsValid(ply) then return "?" end
    local f = ply:GetNW2String("lcf_faction", "")
    if (f == "cp") and ply:GetNW2String("lcf_title", "") ~= "" then return ply:GetNW2String("lcf_title", "") end
    if LC_CL.Knows and LC_CL.Knows(ply) and ply:GetNW2String("lc_char", "") ~= "" then return ply:GetNW2String("lc_char", "") end
    local d = LC_CL.Description and LC_CL.Description(ply) or ply:Nick()
    if #d > 34 then d = string.sub(d, 1, 32) .. "..." end
    return d
end

local menu

-- Build the menu from who you are and what's in front of you.
function LC_CL.OpenActions()
    if IsValid(menu) then menu:Remove() menu = nil return end
    local me = LocalPlayer()
    if not IsValid(me) or not me:Alive() then return end
    local now = CurTime()
    local f = me:GetNW2String("lcf_faction", "")
    local unit = me:GetNW2Bool("lc_unit", false) or f == "cp"
    local rebel = f == "resistance"
    local standing = me:GetNW2Int("lce_standing", 0)
    local downed = me:GetNW2Float("lc_downed_until", 0) > now
    local tr = me:GetEyeTrace()
    local e = tr and tr.Entity
    local close = tr and tr.HitPos and tr.HitPos:DistToSqr(me:EyePos()) < 150 * 150
    local person = IsValid(e) and e:IsPlayer() and close and e or nil
    local cls = IsValid(e) and e:GetClass() or ""
    local isDoor = close and (cls == "func_door" or cls == "func_door_rotating" or cls == "prop_door_rotating" or cls == "func_movelinear")

    menu = DermaMenu()
    local function Add(m, label, fn, icon)
        local o = m:AddOption(label, fn)
        if icon then o:SetIcon(icon) end
        return o
    end
    -- the screens everyone has
    -- what now? (sv_livingcity_nextstep.lua): the next step, and the way to everywhere
    local step = LC_CL.NextStep and LC_CL.NextStep()
    if step then
        Add(menu, "What now? " .. step.text .. (step.way ~= "" and " (show me the way)" or ""), function()
            if step.way ~= "" then Send("waypoint", step.way) end
            if LC_CL.AddNotice then LC_CL.AddNotice(step.urgent and "warn" or "info", step.text, step.why) end
        end, "icon16/flag_green.png")
    end
    if LC_CL.PlacesPage then
        local places, po = menu:AddSubMenu("Places in the city (show me the way)")
        po:SetIcon("icon16/map.png")
        for _, it in ipairs(LC_CL.PlacesPage().items) do Add(places, it.label, it.run) end
    end
    if unit then Add(menu, "Unit tools (Civil Protection)", function() if LC_CL.OpenUnitTools then LC_CL.OpenUnitTools() end end, "icon16/shield.png") end
    -- a shackled vortigaunt: calling the Resistance through the vortessence (sv_livingcity_vortwork.lua)
    if f == "vort" then Add(menu, "Reach out through the vortessence (call the Resistance to free you)", function() Send("vortcall") end, "icon16/transmit.png") end
    Add(menu, "Guide / manual", function() if LC_OpenGuide then LC_OpenGuide(me:IsAdmin()) else RunConsoleCommand("lc_help") end end, "icon16/book_open.png")
    Add(menu, "My pockets (F2)", function() RunConsoleCommand("gm_showteam") end, "icon16/briefcase.png")
    Add(menu, "My board: jobs and stories (F3)", function() RunConsoleCommand("gm_showspare1") end, "icon16/page_white_text.png")
    Add(menu, "Factions (F4)", function() RunConsoleCommand("gm_showspare2") end, "icon16/group.png")
    Add(menu, "Tips I've seen (read them again)", function() net.Start("lc_hints_list") net.SendToServer() end, "icon16/lightbulb.png")
    menu:AddSpacer()

    -- the person in front of you
    if person then
        local sub, opt = menu:AddSubMenu(LC_CL.ICName(person))
        opt:SetIcon("icon16/user.png")
        Add(sub, "Recognize (tell them your name)", function() Send("recognize") end)
        if not unit then Add(sub, "Show them my papers", function() Send("showpapers") end, "icon16/vcard.png") end
        if not unit and not rebel then Add(sub, "Inform on them to Civil Protection", function() Send("inform", "", person) end, "icon16/eye.png") end
        if me:GetNW2Bool("lc_foreman", false) then Add(sub, "Give them a work order (foreman)", function() Send("assign", "", person) end, "icon16/wrench.png") end
        Add(sub, "Cuff them", function() Send("tie") end)
        if person:GetNW2Bool("lc_tied", false) then
            Add(sub, "Uncuff them", function() Send("untie") end)
            Add(sub, "Drag them along / let go", function() Send("drag") end)
        end
        if unit then Add(sub, "Search them", function() Send("search") end, "icon16/magnifier.png") end
        if unit and person:GetNW2String("lcj_job", "") ~= "" and person:GetNW2Entity("lc_escorting") ~= me then
            Add(sub, "Escort them (a worker on a job)", function() Send("escort", "", person) end, "icon16/group_go.png")
        end
        if person:GetNW2Bool("lc_tied", false) or person:GetNW2Bool("lc_handsup", false) then
            Add(sub, "Take their microphone (if they have one)", function() Send("takemic", "", person) end, "icon16/sound.png")
        end
        if rebel and person:GetNW2String("lcf_faction", "") == "vort" then Add(sub, "Cut the vortigaunt's shackles", function() Send("unshackle") end) end
        Add(sub, "Give them a key to my apartment", function() Send("givekey") end, "icon16/key_add.png")
        Add(sub, "Take my apartment key back from them", function() Send("takekey") end, "icon16/key_delete.png")
    end
    -- someone who's down (sv_livingcity_rp.lua)
    if close and IsValid(e) and e:GetNW2Bool("lc_downed_body", false) then
        local sub, opt = menu:AddSubMenu("Someone who's down")
        opt:SetIcon("icon16/heart.png")
        Add(sub, "Drag them along / let go", function() Send("drag") end, "icon16/arrow_right.png")
        Add(sub, unit and "Help them up, or cuff them if they're wanted: hold E on them" or "Help them up: hold E on them", function() end)
    end

    -- a body
    if close and IsValid(e) and e:GetNW2Bool("lc_body", false) then
        local sub, opt = menu:AddSubMenu("This body")
        opt:SetIcon("icon16/cross.png")
        Add(sub, "Search their pockets", function() Send("searchbody", "", e) end, "icon16/magnifier.png")
        Add(sub, "Haul them (drag to an incinerator)", function() Send("haul", "", e) end, "icon16/arrow_right.png")
    end

    -- the thing in front of you
    if isDoor then
        local sub, opt = menu:AddSubMenu("This door")
        opt:SetIcon("icon16/door.png")
        Add(sub, "Rent it / lock it (apartments)", function() Send("rent") end)
        Add(sub, "Pick the lock (needs a lockpick)", function() Send("pick") end)
        if me:HasWeapon("weapon_lc_multitool") then Add(sub, "Hack the Combine lock (multitool)", function() Send("hack") end, "icon16/lightning.png") end
    end
    -- the power grid and forcefields (sv_livingcity_power.lua)
    if close and cls == "lc_transformer" then
        local sub, opt = menu:AddSubMenu("This transformer")
        opt:SetIcon("icon16/lightning.png")
        if e:GetNW2Bool("lc_down", false) then
            Add(sub, "Repair it (Maintenance Technicians)", function() Send("transformer", "", e) end, "icon16/wrench.png")
        elseif me:HasWeapon("weapon_lc_multitool") then
            Add(sub, "Sabotage it: the district goes dark (multitool)", function() Send("sabotage", "", e) end, "icon16/lightning_delete.png")
        else
            Add(sub, "It hums. (A multitool could short it out.)", function() end)
        end
    end
    -- checkpoints (sv_livingcity_checkpoints.lua)
    if close and cls == "lc_powerbank" then
        local sub, opt = menu:AddSubMenu("This power bank")
        opt:SetIcon("icon16/lightning.png")
        if unit then
            Add(sub, "Read it (what it's powering)", function() Send("checkpoint", "status", e) end, "icon16/information.png")
            Add(sub, "Take it down (officers)", function() Send("checkpoint", "packbank", e) end, "icon16/delete.png")
        elseif me:HasWeapon("weapon_lc_multitool") then
            Add(sub, "Short it out: the turrets and forcefields on it die (multitool)", function() Send("checkpoint", "short", e) end, "icon16/lightning_delete.png")
        else
            Add(sub, "It hums. (A multitool could short it out.)", function() end)
        end
    end
    if close and cls == "npc_turret_floor" and unit then
        Add(menu, "Pack up this turret", function() Send("checkpoint", "pack", e) end, "icon16/arrow_undo.png")
    end
    if close and cls == "lc_forcefield" then
        local sub, opt = menu:AddSubMenu("This forcefield")
        opt:SetIcon("icon16/shield.png")
        Add(sub, "Swipe a Combine keycard", function() Send("swipe", "", e) end, "icon16/key.png")
        if me:HasWeapon("weapon_lc_multitool") then Add(sub, "Short it out for a minute (multitool)", function() Send("shortfield", "", e) end) end
    end
    if close and cls == "lc_screen" and me:HasWeapon("weapon_lc_multitool") then Add(menu, "Hijack this city screen (multitool)", function() Send("hijack") end, "icon16/television.png") end

    -- yourself
    local you, yo = menu:AddSubMenu("Me")
    yo:SetIcon("icon16/user_gray.png")
    if downed then Add(you, "Give up (let go)", function() Send("giveup") end, "icon16/cross.png") end
    Add(you, me:GetNW2Bool("lc_handsup", false) and "Lower my hands" or "Put my hands up", function() Send("handsup") end)
    Add(you, "Holster / draw", function() Send("holster") end)
    if me:GetNW2Bool("lc_tied", false) then Add(you, "Work at the cuffs", function() Send("struggle") end) end
    if me:GetNW2Float("lc_wanted_until", 0) > now then Add(you, "Give myself up (near a Civil Protection unit)", function() Send("surrender") end) end
    if me:GetNW2Bool("lc_interrogated", false) then
        Add(you, "Talk to the interrogator", function() net.Start("lc_interrogate_reply") net.WriteBool(true) net.SendToServer() end, "icon16/comment.png")
    end
    if me:GetNW2Bool("lc_hauling", false) then Add(you, "Let go of the body", function() Send("haul") end) end
    if GetGlobal2String("lc_event", "") == "rations" or me:GetNW2Bool("lc_ration_break", false) then
        if me:GetNW2Bool("lc_ration_break", false) then Add(you, "Back to work (end the ration break)", function() Send("back") end, "icon16/arrow_redo.png")
        else Add(you, "Take a ration break (the job waits till you've had your ration)", function() Send("rationbreak") end, "icon16/cup.png") end
    end
    if me:GetNW2String("lcj_job", "") == "mortuary" then Add(you, "Take a body cart, or leave it (by the incinerator or the morgue)", function() Send("bodycart") end, "icon16/lorry.png") end
    if IsValid(me:GetNW2Entity("lc_scanner")) then Add(you, "Disconnect from the scanner", function() Send("unlink") end) end
    local poses = you:AddSubMenu("Pose")
    for _, p in ipairs({ "sit", "kneel", "lie", "lean", "cower" }) do Add(poses, Title(p), function() Send(p) end) end
    for i = 1, 4 do Add(poses, "Stand: pose " .. i, function() Send("pose", tostring(i)) end) end
    Add(poses, "Stand up", function() Send("stand") end)
    local gest = you:AddSubMenu("Gesture")
    local names = {}
    for n in pairs(LCA and LCA.Gestures or {}) do names[#names + 1] = n end
    table.sort(names)
    for _, n in ipairs(names) do Add(gest, Title(n), function() Send(n) end) end
    Add(you, "My papers", function() Send("papers") end, "icon16/vcard.png")
    Add(you, "Show my papers to whoever I'm looking at", function() Send("showpapers") end, "icon16/vcard_edit.png")
    Add(you, "My credits and standing", function() Send("credits") end, "icon16/coins.png")
    Add(you, "My characters (switch, or start someone new)", function() Send("characters") end, "icon16/group.png")
    Add(you, "Change my name and face", function() Send("character") end)
    Add(you, "Change how strangers see me (description)", function()
        Ask("How strangers see you", "Describe yourself (8 to 120 characters), e.g. tall, grey coat, a scar over one eye", "chardesc", me:GetNW2String("lc_desc", ""))
    end)
    Add(you, "I'm stuck", function() Send("stuck") end)

    -- talking (the same as the chat prefixes)
    local talk, to = menu:AddSubMenu("Talk")
    to:SetIcon("icon16/comments.png")
    Add(talk, "Tell everyone nearby my name", function() Send("recognize", "all") end, "icon16/user_add.png")
    Add(talk, "Yell...", function() Say("Yell", "What do you yell?", "/y ") end)
    Add(talk, "Whisper (to whoever is right next to you)...", function() Say("Whisper", "What do you whisper?", "/w ") end)
    Add(talk, "Describe what I do (/me)...", function() Say("An action", "What do you do? (e.g. leans against the wall)", "/me ") end)
    Add(talk, "Describe the scene (/it)...", function() Say("The scene", "What happens? (e.g. A siren starts up somewhere.)", "/it ") end)
    Add(talk, "Roll the dice (1 to 100)", function() RunConsoleCommand("say", "/roll") end)
    Add(talk, "Out of character, nearby...", function() Say("Out of character", "Said out of character, to people nearby", "/looc ") end)
    Add(talk, "Out of character, everyone...", function() Say("Out of character", "Said out of character, to the whole server", "// ") end)
    Add(talk, "On my radio...", function() Ask("Radio", "What do you say on the radio?", "r") end, "icon16/transmit.png")

    -- getting by
    local by, byo = menu:AddSubMenu("Getting by")
    byo:SetIcon("icon16/basket.png")
    Add(by, "Open my stash (at home)", function() Send("stash") end)
    Add(by, "Union Commissary (at a terminal)", function() Send("shop") end, "icon16/cart.png")
    Add(by, "Black market (at a dealer, or in rebel territory)", function() Send("market") end, "icon16/money.png")
    Add(by, "Write something (needs paper)", function() Send("write") end, "icon16/pencil.png")
    Add(by, "Fish (needs a line, at water)", function() Send("fish") end)
    Add(by, "Salvage the junk I'm looking at (crowbar)", function() Send("salvage") end)
    Add(by, "Request Civil Protection (with a call box)", function() Ask("Request", "What's wrong?", "request") end)
    -- a Union worker whose job is behind Combine doors (sv_livingcity_escort.lua)
    if not unit and me:GetNW2String("lcj_job", "") ~= "" then
        if me:GetNW2String("lc_escort_phase", "") ~= "" or me:GetNW2Bool("lc_escort_wait", false) then
            Add(by, "Send my escort away", function() Send("escort") end, "icon16/group_delete.png")
        else
            Add(by, "Ask for a Civil Protection escort (on a job, through Combine doors)", function() Send("escort") end, "icon16/group_go.png")
        end
    end
    if not unit and not rebel and standing >= 150 then
        Add(by, me:GetNW2Bool("lc_foreman", false) and "Stop being a Union foreman" or "Become a Union foreman", function() Send("foreman") end, "icon16/wrench.png")
    end

    -- home
    local home, ho = menu:AddSubMenu("Home")
    ho:SetIcon("icon16/house.png")
    Add(home, "My housing block", function() Send("block") end)
    Add(home, "Show me the way home (mark it)", function() Send("waypoint", "home") end, "icon16/map.png")
    if me:GetNW2Bool("lc_unreg", false) then Add(home, "Show me the way to Civil Intake", function() Send("waypoint", "intake") end, "icon16/map.png") end
    if me:GetNW2Bool("lc_unhoused", false) then Add(home, "Show me the way to Housing Allocation", function() Send("waypoint", "housing") end, "icon16/map.png") end
    Add(home, "About my apartment", function() Send("apartment") end)
    Add(home, "Lock my apartment (looking at its door)", function() Send("lock") end, "icon16/lock.png")
    Add(home, "Unlock my apartment (looking at its door)", function() Send("unlock") end, "icon16/lock_open.png")
    Add(home, "Take a key back from...", function() Ask("Take a key back", "Whose key? (their name)", "takekey") end, "icon16/key_delete.png")
    Add(home, "Give up my apartment", function()
        Derma_Query("Give up your apartment? Your rent isn't refunded.", "Give up the apartment", "Give it up", function() Send("unrent") end, "Keep it")
    end)

    -- the city
    local city, co = menu:AddSubMenu("The city")
    co:SetIcon("icon16/world.png")
    Add(city, "The time and the weather", function() Send("time") end, "icon16/clock.png")
    Add(city, "Who holds the city", function() Send("city") end, "icon16/chart_pie.png")
    Add(city, "The city's laws", function() Send("laws") end, "icon16/script.png")
    if me:IsAdmin() or f == "admin" or (f == "cp" and me:GetNW2Int("lcf_rank", 1) >= 3) then
        Add(city, "Broadcast to the whole city...", function() Ask("Broadcast", "What does the city hear?", "broadcast") end, "icon16/sound.png")
    end

    -- Civil Protection
    if unit then
        local cp, cpo = menu:AddSubMenu("Civil Protection")
        cpo:SetIcon("icon16/shield.png")
        Add(cp, "Unit tools (everything, with what it does)", function() if LC_CL.OpenUnitTools then LC_CL.OpenUnitTools() end end, "icon16/application_view_tile.png")
        Add(cp, "Call for backup", function() Send("backup") end)
        Add(cp, "Send my 10-20 (my position)", function() Send("10-20") end)
        Add(cp, "Records terminal", function() Send("records") end)
        Add(cp, "Find the Civil Protection Commissary (supplies; mark it)", function() Send("waypoint", "cpsupply") end, "icon16/map.png")
        Add(cp, "Mask voice lines", function() Send("vo") end)
        Add(cp, "Issue a BOLO", function() Ask("BOLO", "What should Civil Protection units look out for?", "bolo") end)
        Add(cp, "Read the mail (at the post office)", function() Send("readmail") end, "icon16/email_open.png")
        Add(cp, "Deploy a turret here (at a checkpoint: near a power bank or forcefield)", function() Send("checkpoint", "turret") end, "icon16/gun.png")
        Add(cp, "Put up a power bank on this wall (officers)", function() Send("checkpoint", "bank") end, "icon16/lightning_add.png")
        -- workers waiting for an escort, or left without one, or with an NPC unit a player can take over from
        local escorting = me:GetNW2Entity("lc_escorting")
        if IsValid(escorting) then
            Add(cp, "Hand back the escort of " .. LC_CL.ICName(escorting), function() Send("escort", "drop") end, "icon16/group_delete.png")
        end
        local reqs = LC_CL.EscortRequests and LC_CL.EscortRequests() or {}
        if #reqs > 0 then
            local er = cp:AddSubMenu("Escort requests (" .. #reqs .. ")")
            for _, r in ipairs(reqs) do
                local p = r.ply
                Add(er, "Escort " .. LC_CL.ICName(p) .. " (" .. r.why .. ")", function() Send("escort", "", p) end)
            end
        end
        -- the Resistance's man inside (only they see this: sv_livingcity_insider.lua)
        if LC_CL.Insider then
            local ins = cp:AddSubMenu("Inside (only you see this)")
            Add(ins, "Tip off Freq 7 (where nobody sees or hears you)...", function() Ask("Tip off Freq 7", "What do you tell the Resistance? (The next planned sweep, if any, goes with it.)", "tipoff") end, "icon16/transmit.png")
            Add(ins, "Lose a wanted person's record (-25 standing)...", function() Ask("Lose a record", "Whose record goes missing? (Their name.)", "loserecord") end)
            Add(ins, "Take supplies for a dead drop (at the Commissary; -10 standing)", function() Send("skim") end)
            Add(ins, "Copy the city's records (the best intel)", function() Send("copyrecords") end)
            Add(ins, "Foul the spare mask filters (at the Commissary; weedkiller)", function() Send("foulfilters") end)
            Add(ins, "Spike the station's food (at the Commissary; weedkiller)", function() Send("spikefood") end)
            Add(ins, "Reveal myself to whoever I'm looking at (the codeword)", function() Send("reveal") end)
        end
        local so = cp:AddSubMenu("Set sociostability (officers)")
        for _, l in ipairs({ "green", "yellow", "red", "auto" }) do Add(so, string.upper(l), function() Send("socio", l) end) end
    end

    -- the Resistance
    if rebel then
        local rs, rso = menu:AddSubMenu("Resistance")
        rso:SetIcon("icon16/flag_red.png")
        Add(rs, "Change into plain clothes", function() Send("plain") end)
        Add(rs, "Gear up (Resistance clothes)", function() Send("gearup") end)
        Add(rs, "Black market (here, in rebel territory)", function() Send("market") end, "icon16/money.png")
        Add(rs, "Find the lab (the scientist makes our guns; mark it)", function() Send("waypoint", "lab") end, "icon16/map.png")
        Add(rs, "Donate food to the supply crate", function() Send("donate") end)
        Add(rs, "Decode a data chip (at the lab)", function() Send("decode") end)
        Add(rs, "Write down what you see (intel the quartermaster buys; needs paper)", function() Send("scout") end, "icon16/page_white_edit.png")
        if me:HasWeapon("weapon_lc_multitool") then Add(rs, "Hack the Combine door I'm looking at", function() Send("hack") end) end
        if me:GetNW2Int("lc_squad_n", 0) > 0 then
            Add(rs, "Squad: act casual (guns away, plain clothes: units take them for citizens)", function() Send("casual") end, "icon16/user_gray.png")
            Add(rs, "Squad: guns out", function() Send("gunsout") end, "icon16/gun.png")
            Add(rs, "Squad: go on ahead and meet me at the job's marker", function() Send("meet") end, "icon16/flag_green.png")
        end
    end

    -- settings, just for you
    local set, seto = menu:AddSubMenu("Settings")
    seto:SetIcon("icon16/cog.png")
    local bob = GetConVar("lc_my_view_bob")
    Add(set, (bob and bob:GetBool() and "Camera sway: on (turn off)") or "Camera sway: off (turn on)", function() RunConsoleCommand("lc_bob_toggle") end)
    local wn = GetConVar("lc_whatnow_show")
    local wm = wn and wn:GetInt() or 1
    Add(set, wm == 2 and "Next step on screen: always (change)" or (wm == 1 and "Next step on screen: new life and urgent (change)" or "Next step on screen: never (change)"),
        function() RunConsoleCommand("lc_whatnow_show", tostring((wm + 1) % 3)) end)
    local scr = GetConVar("lc_screen_ui")
    Add(set, (scr and scr:GetBool()) and "Terminals' menus: on their own screen (use a window)" or "Terminals' menus: in a window (use their own screen)",
        function() RunConsoleCommand("lc_screen_ui", (scr and scr:GetBool()) and "0" or "1") end)
    local third = GetConVar("lc_act_thirdperson")
    Add(set, (third and third:GetBool() and "Third person while posing: on (turn off)") or "Third person while posing: off (turn on)",
        function() RunConsoleCommand("lc_act_thirdperson", (third and third:GetBool()) and "0" or "1") end)
    local notes = GetConVar("lc_notices")
    Add(set, (notes and notes:GetBool() and "Warnings and notices on screen: on (turn off)") or "Warnings and notices on screen: off (turn on)",
        function() RunConsoleCommand("lc_notices", (notes and notes:GetBool()) and "0" or "1") end)
    Add(set, "Tips: turn off", function() Send("hints", "off") end)
    Add(set, "Tips: turn on", function() Send("hints", "on") end)
    Add(set, "Tips: show me them all again, from the start", function() Send("hints", "reset") end)

    -- help, and staff
    local help, helpo = menu:AddSubMenu("Help")
    helpo:SetIcon("icon16/help.png")
    Add(help, "Ask staff for help...", function() Ask("Ask staff", "What's wrong? Staff see this as a ticket.", "ticket") end, "icon16/user_comment.png")
    if me:IsAdmin() then
        Add(help, "Staff panel (logs, tickets, warnings, bans)", function() Send("staff") end, "icon16/shield_go.png")
        Add(help, "Admin testing tools", function() Send("admintools") end, "icon16/wrench_orange.png")
        Add(help, me:GetNW2Bool("lc_build", false) and "Build mode: on (back to playing)" or "Build mode: off (spawn menu, physgun, editor)", function() Send("build") end, "icon16/brick.png")
        Add(help, "Path mapping: on / off (walk to draw NPC paths)", function() Send("pathmap") end, "icon16/map.png")
        Add(help, (LC_CL.LagWatchOn and LC_CL.LagWatchOn()) and "Lag monitor: on (turn off)" or "Lag monitor: off (what's causing lag, live)",
            function() if LC_CL.SetLagWatch then LC_CL.SetLagWatch() end end, "icon16/chart_line.png")
        if me:IsSuperAdmin() then
            Add(help, "Endings menu (tune the secret endings live)", function() if LC_CL.EndingsMenu then LC_CL.EndingsMenu() end end, "icon16/music.png")
        end
    end

    -- a cursor to click with, for as long as the menu is up
    gui.EnableScreenClicker(true)
    local function Done() timer.Simple(0, function() if not IsValid(menu) then gui.EnableScreenClicker(false) end end) end
    menu.OnRemove = Done
    menu:Open()
    menu:Center()
    LC_CL.ActionsOpenedAt = CurTime()
end

-- Workers who want a unit with them: waiting, left alone, or with an NPC unit a player can take over from.
function LC_CL.EscortRequests()
    local me = LocalPlayer()
    local escorting = IsValid(me) and me:GetNW2Entity("lc_escorting") or nil
    local out = {}
    for _, p in ipairs(player.GetAll()) do
        local ph, esc = p:GetNW2String("lc_escort_phase", ""), p:GetNW2Entity("lc_escort")
        if p ~= escorting and (p:GetNW2Bool("lc_escort_wait", false) or ph == "unattended" or (ph ~= "" and IsValid(esc) and not esc:IsPlayer())) then
            local why = (ph == "unattended" and "unattended") or (p:GetNW2Bool("lc_escort_wait", false) and "waiting") or "with an NPC Civil Protection unit"
            out[#out + 1] = { ply = p, why = why }
        end
    end
    return out
end

concommand.Add("lc_actions", function() LC_CL.OpenActions() end)

function LC_CL.ActionsOpen() return IsValid(menu) end

-- F1: the quick menu (cl_livingcity_quick.lua), whose 9 is this one. F1 again
-- closes whichever is open, or the guide if that's what's open.
local f1Was = false
hook.Add("Think", "LivingCityActionsKey", function()
    local down = input.IsKeyDown(KEY_F1)
    if down and not f1Was and not gui.IsGameUIVisible() and not vgui.GetKeyboardFocus() then
        if LC_CL.QuickOpen and LC_CL.QuickOpen() then LC_CL.CloseQuick()
        elseif IsValid(menu) then menu:Remove() menu = nil
        elseif LC_GuideOpen and LC_GuideOpen() then LC_CloseGuide()
        elseif LC_CL.OpenQuick then LC_CL.OpenQuick()
        else LC_CL.OpenActions() end
        LC_CL.ActionsOpenedAt = CurTime()
    end
    f1Was = down
end)

-- C opens it straight away (except in build mode, where C is the build menu)
hook.Add("PlayerBindPress", "LivingCityActions", function(ply, bind, pressed)
    if not pressed or not string.find(bind, "+menu_context", 1, true) then return end
    if not GAMEMODE or GAMEMODE:LCBuilder(ply) then return end
    LC_CL.OpenActions()
    return true
end)

------------------------------------------------------------------------
-- Interrogation: the choice, on screen
------------------------------------------------------------------------

local frame
net.Receive("lc_interrogate", function()
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetTitle("Interrogation")
    frame:SetSize(420, 170)
    frame:Center()
    frame:MakePopup()
    frame:ShowCloseButton(false)
    local l = vgui.Create("DLabel", frame)
    l:Dock(TOP)
    l:DockMargin(8, 4, 8, 8)
    l:SetWrap(true)
    l:SetTall(54)
    l:SetText("A Civil Protection unit stands over you with a stun baton. \"You will answer my questions.\"\n\nTalk, and the beating stops: you give up a Resistance hideout. Say nothing, and take it.")
    local talk = vgui.Create("DButton", frame)
    talk:Dock(TOP)
    talk:DockMargin(8, 0, 8, 4)
    talk:SetTall(28)
    talk:SetText("Talk (give them a hideout)")
    talk.DoClick = function()
        net.Start("lc_interrogate_reply") net.WriteBool(true) net.SendToServer()
        frame:Remove()
    end
    local quiet = vgui.Create("DButton", frame)
    quiet:Dock(TOP)
    quiet:DockMargin(8, 0, 8, 4)
    quiet:SetTall(28)
    quiet:SetText("Say nothing")
    quiet.DoClick = function()
        net.Start("lc_interrogate_reply") net.WriteBool(false) net.SendToServer()
        frame:Remove()
    end
    local baseThink = frame.Think -- (DFrame's own: dragging the window)
    frame.Think = function(self)
        if baseThink then baseThink(self) end
        if not LocalPlayer():GetNW2Bool("lc_interrogated", false) and (self.born or 0) + 2 < CurTime() then self:Remove() end
    end
    frame.born = CurTime()
end)
