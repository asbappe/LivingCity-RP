--[[
    Living City: testing a dream from the editor

      The owner, 8 November: "please add a way to test dreams in the living city editor".

      The Living City Editor's panel (Q menu > the editor tool) has a "Dreams: test one" section:
      pick any dream (every secret ending and every dream you play, by mood) and "Test it now
      (just me)". You go into it straight away, awake, at the dream point, alone (the city's
      named people stand in, as in any dream with too few dreamers: lc_dream_min). Nobody asleep
      is pulled in, and it isn't tonight's dream: nothing about tonight changes.
      A test leaves nothing behind: you can stop it whenever you like (the panel's "Stop the test",
      or C > Settings > Shared dreams: wake up), you're never an Enforcer in it (you play it), and
      waking you're put back exactly as you were, with nothing won or lost (no Unbroken, no loyalty
      points, no health, no dream counted towards the lab's foil hat or chip).
      Who may: whoever may use the editor (LC.CanEdit: superadmins). It needs a dream point and
      dreams on (lc_dreams), like any dream.
      A test is recorded for the code chat while the panel's "Record the test" box is ticked
      (the flight recorder: sv_livingcity_dreamrec.lua); nothing else ever is.
]]

if CLIENT then return end

LC = LC or {}

util.AddNetworkString("lc_dream_test") -- client > server: "list", "test" <id>, "stop"; server > client: the list and what's going on

local function Notice(p, kind, title, text, secs)
    if not IsValid(p) then return end
    if LC.Notice then LC.Notice(p, kind, title, text, secs) elseif p.ChatPrint then p:ChatPrint(title .. ": " .. text) end
end
local function CanTest(p)
    if not IsValid(p) then return false end
    if LC.CanEdit then return LC.CanEdit(p) == true end
    return p:IsSuperAdmin()
end

-- Every dream there is, by mood (Happy, Neutral, Nightmare; propaganda under Happy): { id, name, mood, kind }.
function LC.DreamTestList()
    local out = {}
    local moods = LC.DreamMoods and LC.DreamMoods() or {}
    local function Add(id, kind)
        local mood = moods[id] or "neutral"
        local name = LC.DreamTitle and LC.DreamTitle(id) or id
        if LC.PropagandaDreams and LC.PropagandaDreams[id] then name = "Propaganda: " .. name end
        out[#out + 1] = { id = id, name = name, mood = LC.DreamMoodNames and LC.DreamMoodNames[mood] or mood, kind = kind }
    end
    for _, id in ipairs(LC.DreamGameOrder or {}) do if LC.DreamGames and LC.DreamGames[id] then Add(id, "game") end end
    for _, id in ipairs(LC.EndingOrder or {}) do if LC.Endings and LC.Endings[id] then Add(id, "ending") end end
    local rank = { Happy = 1, Neutral = 2, Nightmare = 3 }
    for i, e in ipairs(out) do e.order = i end
    table.sort(out, function(a, b)
        local ra, rb = rank[a.mood] or 9, rank[b.mood] or 9
        if ra ~= rb then return ra < rb end
        return a.order < b.order
    end)
    return out
end

-- Into a dream now, alone and awake. True and the dream, or false and why not.
function LC.DreamTest(p, id)
    if not CanTest(p) then return false, "Only those who may use the Miscount Editor can test dreams." end
    id = string.lower(tostring(id or ""))
    if not (LC.DreamKnown and LC.DreamKnown(id)) then return false, "No such dream." end
    if LC.DreamActive then return false, "A dream is already under way. Wait for it to end, or wake everyone (C > Help > Dreams)." end
    if p.lcDreaming then return false, "You're already dreaming." end
    if not p:Alive() then return false, "You have to be alive to dream." end
    if p.lcSleep then return false, "Get out of bed first (a test is dreamt awake)." end
    p.lcDreamTesting = true
    LC.DreamTestOnly = p
    if LC.DreamRecBegin then pcall(LC.DreamRecBegin, p, id) end -- (the flight recorder: sv_livingcity_dreamrec.lua)
    local okCall, ok, dream = pcall(LC.DreamStart, id, p, false, p, true)
    LC.DreamTestOnly = nil
    if not (okCall and ok) and LC.DreamRecAbort then pcall(LC.DreamRecAbort) end
    if not okCall then
        p.lcDreamTesting = nil
        if LC.Error then LC.Error("dream test", ok) end
        return false, "The dream couldn't start (see the server's errors)."
    end
    if not ok then
        p.lcDreamTesting = nil
        return false, tostring(dream or "The dream couldn't start.")
    end
    p:SetNW2Bool("lc_dream_test", true)
    if LC.Log then LC.Log("info", "Dream test: " .. p:Nick() .. " is testing " .. id) end
    return true, dream
end

-- Out of the test now (the dream ends, since nobody else is in it but stand-ins).
function LC.DreamTestStop(p)
    if not IsValid(p) or not p.lcDreaming then return false, "You aren't dreaming." end
    local dream = LC.DreamActive
    if not (dream and dream.test) then return false, "This isn't a test: wake up from C > Settings > Shared dreams once you're out of it." end
    LC.DreamWakeOne(p, "test")
    return true
end

local function SendList(p)
    net.Start("lc_dream_test")
    net.WriteTable({ k = "list", list = LC.DreamTestList(), point = LC.DreamPoint and LC.DreamPoint() ~= nil or false,
        on = GetConVar("lc_dreams") == nil or GetConVar("lc_dreams"):GetBool() })
    net.Send(p)
end

net.Receive("lc_dream_test", function(_, p)
    if not IsValid(p) then return end
    local what, arg = net.ReadString(), net.ReadString()
    if what == "stop" then
        local ok, why = LC.DreamTestStop(p)
        if not ok then Notice(p, "warn", "Dream test", why, 5) end
        return
    end
    if not CanTest(p) then Notice(p, "warn", "Dream test", "Only those who may use the Miscount Editor can test dreams.", 5) return end
    if what == "list" then SendList(p) return end
    if what == "test" then
        local ok, why = LC.DreamTest(p, arg)
        if ok then
            Notice(p, "info", "Dream test", "Testing \"" .. (LC.DreamTitle and LC.DreamTitle(arg) or arg) .. "\". Stop whenever you like: the editor's Stop the test, or C > Settings > Shared dreams. Nothing you win or lose counts.", 10)
        else
            Notice(p, "warn", "Dream test", tostring(why), 6)
        end
    end
end)
