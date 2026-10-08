--[[
    Living City (client): Unit tools

    A Civil Protection unit's (or Overwatch soldier's) tools in one window,
    each with a line saying what it does, so nobody has to know a command:

      Dispatch          call for backup, send your 10-20, issue a BOLO
      Records           the records terminal: citizens, violations, BOLOs, requests
      Your mask         the voice lines
      In front of you   search, zip-tie, cut ties, drag, escort, take a microphone
                        (whoever you were looking at when you opened it)
      Checkpoints       a turret, a power bank
      Escorts           workers waiting for one; handing yours back
      Post office       reading the mail
      Sociostability    officers set it
      Your work         your directives (F3)

    C > Unit tools (the full menu), F1 > 6 when nothing's in front of you, or
    bind a key to lc_unittools. Every button runs the same action as the
    menus (cl_livingcity_actions.lua, cl_livingcity_quick.lua).
]]

LC_CL = LC_CL or {}

local INK, DIM, ACCENT = Color(232, 226, 210), Color(160, 158, 150), Color(120, 190, 255)
local PANEL, ROW = Color(12, 16, 22, 245), Color(24, 30, 40, 235)
local SOCIO = { green = Color(110, 200, 120), yellow = Color(235, 200, 80), red = Color(230, 90, 80) }

surface.CreateFont("LCUnitTitle", { font = "Trebuchet MS", size = 26, weight = 700 })
surface.CreateFont("LCUnitHead", { font = "Trebuchet MS", size = 18, weight = 700 })
surface.CreateFont("LCUnitText", { font = "Trebuchet MS", size = 15, weight = 500 })

local frame

function LC_CL.IsUnit(ply)
    if not IsValid(ply) then return false end
    local f = ply:GetNW2String("lcf_faction", "")
    return ply:GetNW2Bool("lc_unit", false) or f == "cp" or f == "ota"
end

function LC_CL.OpenUnitTools()
    if IsValid(frame) then frame:Remove() end
    local me = LocalPlayer()
    local Send, Ask = LC_CL.SendAction, LC_CL.AskAction
    if not IsValid(me) or not Send then return end
    if not LC_CL.IsUnit(me) then
        if chat and chat.AddText then chat.AddText(ACCENT, "[Unit tools] ", INK, "For Civil Protection and Overwatch.") end
        return
    end
    -- whoever is in front of you as you open it
    local tr = me:GetEyeTrace()
    local who = tr and IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.HitPos and tr.HitPos:DistToSqr(me:EyePos()) < 150 * 150 and tr.Entity or nil

    local W, H = math.min(ScrW() - 40, 760), math.min(ScrH() - 40, 680)
    frame = vgui.Create("DFrame")
    frame:SetTitle("")
    frame:SetSize(W, H)
    frame:Center()
    frame:MakePopup()
    local socio = GetGlobal2String("lc_socio", "green")
    local bolos = GetGlobal2Int("lc_bolos", 0)
    frame.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, PANEL)
        draw.SimpleText("UNIT TOOLS", "LCUnitTitle", 16, 10, ACCENT)
        draw.SimpleText(me:GetNW2String("lcf_title", "Unit"), "LCUnitText", 180, 20, INK)
        draw.SimpleText(string.format("Sociostability %s     BOLOs out: %d", string.upper(socio), bolos), "LCUnitText", w - 40, 20,
            SOCIO[socio] or DIM, TEXT_ALIGN_RIGHT)
    end

    local scroll = vgui.Create("DScrollPanel", frame)
    scroll:Dock(FILL)
    scroll:DockMargin(6, 26, 6, 6)

    local function Close() if IsValid(frame) then frame:Remove() end end
    local function Do(cmd, rest, target) return function() Send(cmd, rest, target) Close() end end

    local function Section(title, note)
        local p = vgui.Create("DPanel", scroll)
        p:Dock(TOP)
        p:DockMargin(0, 0, 0, 8)
        p:DockPadding(10, 32, 10, 6)
        p.lcTall = 40
        p:SetTall(p.lcTall)
        p.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, ROW)
            draw.SimpleText(title, "LCUnitHead", 10, 7, INK)
            if note then draw.SimpleText(note, "LCUnitText", w - 10, 9, DIM, TEXT_ALIGN_RIGHT) end
        end
        return p
    end
    local function Grow(sec, by) sec.lcTall = sec.lcTall + by sec:SetTall(sec.lcTall) end
    -- a button, and what it does beside it
    local function Button(sec, label, desc, fn)
        local row = vgui.Create("DPanel", sec)
        row:Dock(TOP)
        row:DockMargin(0, 0, 0, 4)
        row:SetTall(28)
        row.Paint = function() end
        local b = vgui.Create("DButton", row)
        b:Dock(LEFT)
        b:SetWide(250)
        b:SetText(label)
        b.DoClick = fn
        local l = vgui.Create("DLabel", row)
        l:Dock(FILL)
        l:DockMargin(10, 0, 0, 0)
        l:SetFont("LCUnitText")
        l:SetTextColor(DIM)
        l:SetText(desc or "")
        Grow(sec, 32)
        return b
    end
    local function Note(sec, text)
        local l = vgui.Create("DLabel", sec)
        l:Dock(TOP)
        l:SetTall(22)
        l:SetFont("LCUnitText")
        l:SetTextColor(DIM)
        l:SetText(text)
        Grow(sec, 22)
    end

    local s = Section("Dispatch")
    Button(s, "Call for backup", "The nearest units come to you, and see where you are.", Do("backup"))
    Button(s, "Send my 10-20", "Marks where you are on every unit's screen.", Do("10-20"))
    Button(s, "Issue a BOLO...", "Something for every unit to look out for: a face, clothes, a name.", function()
        Close()
        Ask("BOLO", "What should units look out for?", "bolo")
    end)

    s = Section("Records")
    Button(s, "Open the records terminal", "Citizens by name and number: record, loyalty, violations. BOLOs, and requests citizens sent in.", Do("records"))

    s = Section("Your mask")
    Button(s, "Voice lines", "Pick a line and the mask says it (saying the words in chat works too).", Do("vo"))

    s = Section("In front of you", who and LC_CL.ICName and LC_CL.ICName(who) or nil)
    if who then
        local tied, hands = who:GetNW2Bool("lc_tied", false), who:GetNW2Bool("lc_handsup", false)
        Button(s, "Search them", "Pat them down for contraband (your baton's reload does it too).", Do("search"))
        if tied then
            Button(s, "Cut the ties", "Let their hands go.", Do("untie"))
            Button(s, "Drag them along / let go", "Walk them where you're going.", Do("drag"))
        else
            Button(s, "Zip-tie their hands", "Their hands up, down, stopped by a unit, or from behind.", Do("tie"))
        end
        if who:GetNW2String("lcj_job", "") ~= "" and who:GetNW2Entity("lc_escorting") ~= me then
            Button(s, "Escort them", "A worker on a job behind Combine doors: they go through with you.", Do("escort", "", who))
        end
        if tied or hands then
            Button(s, "Take their microphone", "If they have one: no more pirate broadcasts.", Do("takemic", "", who))
        end
        Note(s, "Your baton: left click strikes, right click arrests, reload searches.")
    else
        Note(s, "Look at someone up close, then open Unit tools, to search, tie or drag them.")
        Note(s, "Your baton: left click strikes, right click arrests, reload searches.")
    end

    s = Section("Checkpoints")
    Button(s, "Deploy a turret here", "At a checkpoint: near a power bank or a forcefield.", Do("checkpoint", "turret"))
    Button(s, "Put up a power bank", "Officers. On the wall you're facing; it powers turrets and forcefields near it.", Do("checkpoint", "bank"))

    local escorting = me:GetNW2Entity("lc_escorting")
    local reqs = LC_CL.EscortRequests and LC_CL.EscortRequests() or {}
    s = Section("Escorts", #reqs > 0 and (#reqs .. " waiting") or nil)
    if IsValid(escorting) then
        Button(s, "Hand back my escort", "You're escorting " .. (LC_CL.ICName and LC_CL.ICName(escorting) or "someone") .. ". Another unit takes over.", Do("escort", "drop"))
    end
    for _, r in ipairs(reqs) do
        Button(s, "Escort " .. (LC_CL.ICName and LC_CL.ICName(r.ply) or r.ply:Nick()), "A Union worker on a job (" .. r.why .. ").", Do("escort", "", r.ply))
    end
    if #reqs == 0 and not IsValid(escorting) then Note(s, "Nobody's waiting for an escort.") end

    s = Section("Post office")
    Button(s, "Read the mail", "At the post office: open citizens' letters, looking for contraband and conspiracy.", Do("readmail"))

    s = Section("Sociostability", "officers")
    local row = vgui.Create("DPanel", s)
    row:Dock(TOP)
    row:SetTall(28)
    row.Paint = function() end
    for _, l in ipairs({ "green", "yellow", "red", "auto" }) do
        local b = vgui.Create("DButton", row)
        b:Dock(LEFT)
        b:DockMargin(0, 0, 6, 0)
        b:SetWide(120)
        b:SetText(string.upper(l))
        b.DoClick = Do("socio", l)
    end
    Grow(s, 32)
    Note(s, "Green, yellow or red sets how hard the city is policed; auto lets the city's mood decide.")

    s = Section("Your work")
    Button(s, "My directives (F3)", "What Overwatch wants done: patrols, stops, arrests, for XP and rank.", function() Close() RunConsoleCommand("gm_showspare1") end)
end

concommand.Add("lc_unittools", function() LC_CL.OpenUnitTools() end)
