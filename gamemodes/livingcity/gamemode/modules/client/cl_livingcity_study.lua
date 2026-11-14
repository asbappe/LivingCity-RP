--[[
    Living City: the play study (the player's side)

      The owner, 14 November: "record how I play ... to make baselines to influence the NPC/AI
      behaviour" (sv_livingcity_study.lua has what's recorded and what's left out).

      Here: the switch (F4 > Factions > Admin: play study), a small line on screen while it's on
      (counting, or paused and why), telling the server when the player is out of the game
      window or away from the keys, and saving what the server sends on the player's own PC:

        garrysmod/data/livingcity/study/<date>_<time>_<faction>/log.txt      (as it happens)
        garrysmod/data/livingcity/study/<date>_<time>_<faction>/report.txt   (when it's stopped)

      report.txt is what the code chat reads first: time by who, what and where, jobs, meetings
      with security, what happened and where on the map.
]]

if SERVER then return end

LC_CL = LC_CL or {}

CreateClientConVar("lc_study_afk", "90", true, true, "The play study: seconds with no key or mouse before you count as away from the keys (that time isn't counted)")

local ROOT = "livingcity/study"
local R            -- the study being saved
local state = {}   -- what the server last said (for the window and the line on screen)
local frame
local lastInput = 0

function LC_CL.Studying() return R ~= nil end
function LC_CL.StudyState() return state end

local function Act(what, arg)
    net.Start("lc_study_act")
    net.WriteString(tostring(what or ""))
    net.WriteString(tostring(arg or ""))
    net.SendToServer()
end
LC_CL.StudyAct = Act

local function Fmt(t, kind, text)
    return string.format("[%7.1f] %-6s %s", t, kind, text)
end

local function Mins(n)
    n = math.floor(tonumber(n) or 0)
    if n >= 3600 then return string.format("%dh %02dm", math.floor(n / 3600), math.floor(n % 3600 / 60)) end
    return string.format("%dm %02ds", math.floor(n / 60), n % 60)
end

------------------------------------------------------------------------
-- Away: out of the game window, in the game's menu, or no key or mouse for a while
------------------------------------------------------------------------

local function Watch()
    hook.Add("CreateMove", "LivingCityStudy", function(cmd)
        if not cmd then return end
        if (cmd.GetButtons and cmd:GetButtons() or 0) ~= 0 or (cmd.GetMouseX and cmd:GetMouseX() or 0) ~= 0 or (cmd.GetMouseY and cmd:GetMouseY() or 0) ~= 0 then
            lastInput = CurTime()
        end
    end)
    hook.Add("HUDPaint", "LivingCityStudy", function()
        if not R then return end
        local paused = state.pause
        local text = paused and ("STUDY PAUSED: " .. tostring(paused)) or ("STUDY: counting (" .. Mins(state.counted) .. ")")
        draw.SimpleText(text, "DermaDefault", ScrW() - 12, 8, paused and Color(230, 170, 80, 230) or Color(150, 210, 150, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end)
    lastInput = CurTime()
    timer.Create("LivingCityStudy", 2, 0, function()
        if not R then return end
        local focus = (not system or not system.HasFocus or system.HasFocus()) and not (gui and gui.IsGameUIVisible and gui.IsGameUIVisible())
        -- (typing in chat or a window open is still being here: only the game's own menu and another window count as away)
        Act("input", (focus and "1" or "0") .. "|" .. math.floor(math.max(0, CurTime() - lastInput)))
    end)
end

local function Unwatch()
    hook.Remove("CreateMove", "LivingCityStudy")
    hook.Remove("HUDPaint", "LivingCityStudy")
    timer.Remove("LivingCityStudy")
end

------------------------------------------------------------------------
-- The window (F4 > Factions > Admin: play study)
------------------------------------------------------------------------

local function Fill()
    if not IsValid(frame) then return end
    frame.body:Clear()
    local function Line(text, col)
        local l = vgui.Create("DLabel", frame.body)
        l:Dock(TOP)
        l:DockMargin(8, 4, 8, 0)
        l:SetWrap(true)
        l:SetAutoStretchVertical(true)
        l:SetText(text)
        if col then l:SetTextColor(col) end
        return l
    end
    local function Btn(text, fn)
        local b = vgui.Create("DButton", frame.body)
        b:Dock(TOP)
        b:DockMargin(8, 6, 8, 0)
        b:SetTall(28)
        b:SetText(text)
        b.DoClick = fn
        return b
    end
    Line("Play as you mean the city's people to behave: where you go, how long you stay, how you move, what you do about security. It notes who you are (faction, rank), the zone you're in and whose ground it is, your job, and whether you're in the city or a dream, and keeps each apart. Nothing about any NPC changes by itself: the report goes to the code chat.", Color(200, 196, 186))
    if state.on then
        Line(state.pause and ("PAUSED: " .. tostring(state.pause)) or "ON: counting", state.pause and Color(230, 170, 80) or Color(150, 210, 150))
        Line("Counted " .. Mins(state.counted) .. " of " .. Mins(state.total) .. ". You: " .. tostring(state.who or "?") .. ". Where: " .. tostring(state.where or "?") .. "." ..
            (state.quest and (" On: \"" .. state.quest .. "\".") or "") .. ((state.struck or 0) > 0 and (" Struck so far: " .. state.struck .. ".") or ""))
        Btn("Stop and save", function() Act("stop") end)
        Btn(state.lastQuest and ("Strike the last job: \"" .. state.lastQuest .. "\" (it went wrong or was glitched)") or "Strike the last job (none taken yet)", function() Act("strike_job") end)
        Btn("Strike the last 5 minutes (I wasn't playing it straight)", function() Act("strike_min", 5) end)
        Btn("Discard this whole session (keep nothing)", function() Act("discard") end)
        Line("It pauses by itself while you fly (noclip), hold the editor's tool, the physics gun or the camera, are out of the game window, or leave the keys alone for a minute and a half. A job that fails or is abandoned is kept out of the baselines without your doing anything.", Color(160, 156, 146))
    else
        Line("OFF." .. (state.note == "saved" and " The last session was saved." or state.note == "discarded" and " The last session was discarded." or ""), Color(160, 156, 146))
        Btn("Start: this session counts", function() Act("start") end)
    end
    local afk = vgui.Create("DNumSlider", frame.body)
    afk:Dock(TOP)
    afk:DockMargin(8, 6, 8, 0)
    afk:SetText("Away from the keys after (seconds)")
    afk:SetMinMax(20, 600)
    afk:SetDecimals(0)
    afk:SetConVar("lc_study_afk")
    if LC_CL.StudyLast then
        Line("Last saved: garrysmod/data/" .. LC_CL.StudyLast .. "/ (report.txt and log.txt). Zip the folder and give it to the code chat.", Color(160, 156, 146))
    end
end

function LC_CL.StudyMenu()
    if IsValid(frame) then frame:Remove() end
    frame = vgui.Create("DFrame")
    frame:SetSize(520, 420)
    frame:Center()
    frame:SetTitle("Play study: how I play, for the city's people to learn from")
    frame:MakePopup()
    frame.body = vgui.Create("DScrollPanel", frame)
    frame.body:Dock(FILL)
    Fill()
    Act("status")
end

------------------------------------------------------------------------
-- What the server sends
------------------------------------------------------------------------

net.Receive("lc_study", function()
    local kind, info = net.ReadString(), net.ReadString()
    local n = net.ReadUInt(16) or 0
    local got = {}
    for i = 1, n do got[i] = { net.ReadFloat(), net.ReadString(), net.ReadString() } end

    if kind == "status" then
        state = util.JSONToTable(info or "") or {}
        Fill()
        return
    end
    if kind == "start" then
        local t = util.JSONToTable(info or "") or {}
        local fac = string.gsub(string.lower(tostring(t.faction or "player")), "[^%w_]", "")
        local dir = ROOT .. "/" .. os.date("%Y%m%d_%H%M%S") .. "_" .. fac
        file.CreateDir(dir)
        R = { dir = dir, report = {} }
        file.Write(dir .. "/log.txt", "LIVING CITY: A PLAY STUDY, THE LOG (" .. tostring(t.nick) .. ", " .. tostring(t.map) .. ", " .. os.date("%d %B %Y, %H:%M") .. ")\n" ..
            "[seconds] kind, then what. who/what/place/time: the player's faction and rank, the city or a dream, the zone, the hour. job: taken, stages, over.\n" ..
            "meet: security in sight. event: what happened (the gamemode's own events, used, attacked, jumped...). told: notices. at: map coordinates.\n" ..
            "pause: not counted from here until \"playing again\". strike: taken out by the player. about: what's networked about the player.\n\n")
        Watch()
        return
    end
    if not R then return end
    if kind == "lines" and #got > 0 then
        local out = {}
        for i, l in ipairs(got) do out[i] = Fmt(l[1], l[2], l[3]) end
        file.Append(R.dir .. "/log.txt", table.concat(out, "\n") .. "\n")
    elseif kind == "report" then
        for _, l in ipairs(got) do R.report[#R.report + 1] = l[3] end
    elseif kind == "end" then
        local r = R
        R = nil
        Unwatch()
        if info == "discard" then
            file.Delete(r.dir .. "/log.txt")
            file.Delete(r.dir)
            return
        end
        if #r.report > 0 then file.Write(r.dir .. "/report.txt", table.concat(r.report, "\n") .. "\n") end
        LC_CL.StudyLast = r.dir
        local msg = "Saved on this computer: garrysmod/data/" .. r.dir .. "/ (report.txt and log.txt). Zip the folder and give it to the code chat."
        if LC_CL.AddNotice then LC_CL.AddNotice("info", "Play study", msg, 16) end
        if chat and chat.AddText then chat.AddText(Color(210, 180, 90), "[Play study] ", Color(230, 230, 230), msg) end
        Fill()
    end
end)
