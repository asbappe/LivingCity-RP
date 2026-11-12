--[[
    Living City (server): the Resistance's rules, its atmosphere, kind options and executions

    The owner, 12 November: "to either use kind options or be brutal, even to
    attempt to recruit the prisoner ... a whole system of 'Resistance
    Atmosphere' ... kind of like the Administrator's sociostability system,
    except I would expect the resistance one to not be announced on
    loudspeakers ... the resistance boards can hold this info", "the leader of
    the resistance can set the mood or even rules via their own 'tablet' (aka a
    clipboard they have as a SWEP with paper and checkboxes on it)", and on
    executions: "a Lieutenant or above can give the order and do it themselves,
    but the fighter is supposed to request permission to execute, or can be
    commanded, and executing so without approval is where the option comes in
    to punish them, expel them, stand by them, etc, by the highest ranking
    Resistance member"; "if it's a proper execution, then yeah the character
    dies", otherwise "a close call", "a dice roll might be best".

    The leader    The highest-ranked Resistance player on (a Fighter or above).
                  They carry the clipboard (weapon_lc_rebelclip; also F2).
    The rules     Beatings allowed or not, prisoners may be executed or must be
                  let go, sympathizers off limits or not, a priority, and the
                  mood (left to events, or set). The last rules stand when the
                  leader is away (data/livingcity/rebel_rules.json).
    The mood      calm, wary, desperate or vengeful: from what happens to the
                  cell (losses, arrests, informers found, escapes), fading with
                  time. Never announced: it is written on the Resistance's
                  notice board, with the rules. It changes how the cell's own
                  people question prisoners and how long they hold them.
    Kind options  In the chair: talk without blows, food or water, and asking
                  them to join.
    Executions    At the cage or the chair. A Lieutenant or above does it or
                  gives leave; a Fighter asks leave, or does it without. A
                  proper execution is a player's real death; one without leave
                  is an ordinary death two times in three. Without leave, the
                  highest-ranked member answers: expel, demote, order their
                  execution, or stand by them.

    lc_rebel_rules 1/0 (0: no clipboard, no mood, no executions, no kind options).
]]

LC = LC or {}

local cvOn = CreateConVar("lc_rebel_rules", "1", FCVAR_ARCHIVE, "The Resistance's rules and atmosphere: the leader's clipboard, the cell's mood on its board, kind options in the chair, executions")

local FILE = "livingcity/rebel_rules.json"
local MOODS = { "calm", "wary", "desperate", "vengeful" }
local PRIORITIES = { "lielow", "attack", "pamphlets", "propaganda" }
local PRIORITY_NAME = { lielow = "lie low", attack = "attack the Combine", pamphlets = "spread pamphlets", propaganda = "put up propaganda" }
local MOOD_LINE = {
    calm = "The cell is calm. Nobody is looking over their shoulder.",
    wary = "The cell is wary. Watch who you talk to.",
    desperate = "The cell is desperate. We have lost too many.",
    vengeful = "The cell wants blood for what was done to us.",
}
local LEAVE_SECS, ASK_WAIT, JUDGE_WAIT = 300, 6, 30

LC.RebelRules = LC.RebelRules or { brutal = true, execute = false, sympathizers = false, priority = "lielow", mood = "" }
LC.RebelMood = LC.RebelMood or { fear = 0, anger = 0 }
LC.ExecLeave = LC.ExecLeave or {} -- [target] = { by = the Fighter given leave (nil: anyone), untilT }
LC.ExecAsks = LC.ExecAsks or {}   -- [fighter] = { target, at, officers }
local R = LC.RebelRules

if util.AddNetworkString then
    for _, n in ipairs({ "lc_rebelclip", "lc_rebelclip_do", "lc_exec_ask", "lc_exec_answer", "lc_exec_judge", "lc_exec_judged" }) do util.AddNetworkString(n) end
end

local function On() return cvOn:GetBool() end
local function Roll() return LC.PatdownRoll and LC.PatdownRoll() or math.random() end
local function IsRes(p) return IsValid(p) and p:IsPlayer() and p:GetNW2String("lcf_faction", "") == "resistance" end
local function Rank(p) return p:GetNW2Int("lcf_rank", 1) end
local function Key(p) return LC.MindsWhoKey and LC.MindsWhoKey(p) or nil end
local function Scene(pos, text)
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():DistToSqr(pos) < 600 * 600 then ply:ChatPrint("** " .. text) end
    end
end
local function NameOf(e)
    if not IsValid(e) then return "someone" end
    if e:IsPlayer() then return e:Nick() end
    return (LC.NPCStr and LC.NPCStr(e, "lc_pname", "") ~= "" and LC.NPCStr(e, "lc_pname", "")) or (e.lcProfile and e.lcProfile.name) or "the citizen"
end
local function IdOf(e)
    if not IsValid(e) then return nil end
    if e:IsPlayer() then return Key(e) end
    return e.lcProfile and e.lcProfile.id
end

------------------------------------------------------------------------
-- The leader and the rules
------------------------------------------------------------------------

local function Load()
    if not (file and file.Read) then return end
    local t = util.JSONToTable(file.Read(FILE, "DATA") or "") or {}
    for k, v in pairs(t) do if R[k] ~= nil and type(v) == type(R[k]) then R[k] = v end end
end
local function Save()
    if not (file and file.Write) then return end
    if file.CreateDir then file.CreateDir("livingcity") end
    file.Write(FILE, util.TableToJSON(R, true))
end
pcall(Load)

-- The highest-ranked Resistance player on, a Fighter or above (nil: nobody). except: not this one.
function LC.RebelChief(except)
    local best
    for _, p in ipairs(player.GetAll()) do
        if p ~= except and IsRes(p) and Rank(p) >= 3 and (not best or Rank(p) > Rank(best)) then best = p end
    end
    return best
end
function LC.RebelMayOrder(ply) return IsRes(ply) and Rank(ply) >= 4 end

-- The clipboard's boxes. key: brutal, execute, sympathizers (ticked or not), priority, mood (the next one).
function LC.RebelRuleSet(ply, key)
    if not On() then return false end
    if LC.RebelChief() ~= ply then return false, "The clipboard is the leader's." end
    if key == "brutal" or key == "execute" or key == "sympathizers" then
        R[key] = not R[key]
    elseif key == "priority" then
        local at = 1
        for i, p in ipairs(PRIORITIES) do if p == R.priority then at = i end end
        R.priority = PRIORITIES[at % #PRIORITIES + 1]
    elseif key == "mood" then
        local order = { "", "calm", "wary", "desperate", "vengeful" }
        local at = 1
        for i, m in ipairs(order) do if m == R.mood then at = i end end
        R.mood = order[at % #order + 1]
    else
        return false
    end
    pcall(Save)
    if LC.ChronicleSendFeeds then LC.ChronicleSendFeeds(nil, true) end
    hook.Run("LivingCityRebelRules", ply, key)
    return true
end

------------------------------------------------------------------------
-- The atmosphere
------------------------------------------------------------------------

function LC.RebelMoodPush(fear, anger)
    local m = LC.RebelMood
    m.fear = math.Clamp(m.fear + (fear or 0), 0, 20)
    m.anger = math.Clamp(m.anger + (anger or 0), 0, 20)
end

-- calm, wary, desperate or vengeful: what the leader set, or what events have made it.
function LC.RebelAtmosphere()
    if R.mood ~= "" then return R.mood end
    local m = LC.RebelMood
    if m.anger >= 6 then return "vengeful" end
    if m.fear >= 8 then return "desperate" end
    if m.fear >= 3 or m.anger >= 3 then return "wary" end
    return "calm"
end

-- How the cell's own people behave by it (sv_livingcity_chair.lua, sv_livingcity_rebelhold.lua).
function LC.RebelNoBlows() return On() and not R.brutal end
function LC.RebelAutoHits()
    if not On() then return 4 end
    local a = LC.RebelAtmosphere()
    return a == "calm" and 2 or (a == "vengeful" and 5 or 4)
end
function LC.RebelHoldFactor()
    if not On() then return 1 end
    local a = LC.RebelAtmosphere()
    return a == "desperate" and 0.5 or (a == "vengeful" and 2 or 1)
end

-- What the Resistance's notice board says at the top (sv_livingcity_chronicle.lua): never a number.
function LC.RebelBoardLines()
    if not On() then return {} end
    local out = { MOOD_LINE[LC.RebelAtmosphere()] }
    out[#out + 1] = R.brutal and "Prisoners: hands may be laid on them." or "Prisoners: nobody lays a hand on them."
    out[#out + 1] = R.execute and "An informer may be shot, with leave." or "Prisoners are let go. Nobody is shot."
    out[#out + 1] = (R.sympathizers and "Sympathizers who turn are fair game." or "Sympathizers are off limits.")
        .. " We " .. (PRIORITY_NAME[R.priority] or "lie low") .. "."
    return out
end

-- Fading: a little every minute.
function LC.RebelMoodTick()
    local m = LC.RebelMood
    m.fear, m.anger = m.fear * 0.97, m.anger * 0.97
end
if timer and timer.Create then timer.Create("LivingCityRebelMood", 60, 0, function() LC.RebelMoodTick() end) end

hook.Add("OnNPCKilled", "LivingCityRebelMood", function(npc)
    local st = LC.NPCs and LC.NPCs[npc]
    if st and st.role == "rebel" then LC.RebelMoodPush(1, 1) end
end)
hook.Add("PlayerDeath", "LivingCityRebelMood", function(ply) if IsRes(ply) then LC.RebelMoodPush(1.5, 1.5) end end)
hook.Add("LivingCityIncarcerated", "LivingCityRebelMood", function(who)
    if not IsValid(who) then return end
    local st = (not who:IsPlayer()) and LC.NPCs and LC.NPCs[who]
    if IsRes(who) or (st and st.role == "rebel") then LC.RebelMoodPush(1, 0.5) end
end)

-- Done against the leader's rules: it is known (the board carries it).
function LC.RebelAgainstRules(ply, what, name)
    if not On() or not IsRes(ply) then return false end
    local broke = (what == "brutal" and not R.brutal) or (what == "execute" and not R.execute) or (what == "sympathizer" and not R.sympathizers)
    if not broke then return false end
    local key = Key(ply)
    if key and LC.ChronicleAdd then
        LC.ChronicleAdd({ k = "against_rules", s = key, pred = (what == "brutal" and "laid hands on " or "killed ") .. tostring(name) .. " against the cell's rules", pos = ply:GetPos(), w = 3 })
    end
    return true
end

------------------------------------------------------------------------
-- The clipboard
------------------------------------------------------------------------

function LC.RebelClipSend(ply)
    if not On() or not IsRes(ply) then return false end
    net.Start("lc_rebelclip")
    net.WriteBool(LC.RebelChief() == ply)
    net.WriteBool(R.brutal)
    net.WriteBool(R.execute)
    net.WriteBool(R.sympathizers)
    net.WriteString(PRIORITY_NAME[R.priority] or "lie low")
    net.WriteString(R.mood)
    net.WriteString(LC.RebelSentiment and LC.RebelSentiment() or MOOD_LINE[LC.RebelAtmosphere()])
    net.Send(ply)
    return true
end

net.Receive("lc_rebelclip_do", function(_, ply)
    local key = net.ReadString()
    if (ply.lcClipNext or 0) > CurTime() then return end
    ply.lcClipNext = CurTime() + 0.3
    local ok, why = LC.RebelRuleSet(ply, key)
    if not ok and why then ply:ChatPrint(why) end
    LC.RebelClipSend(ply)
end)

-- The leader carries it; nobody else does.
function LC.RebelClipTick()
    if not On() then return end
    local leader = LC.RebelChief()
    for _, p in ipairs(player.GetAll()) do
        local has = p:HasWeapon("weapon_lc_rebelclip")
        if p == leader and not has and p:Alive() and not (LC.IsTied and LC.IsTied(p)) then p:Give("weapon_lc_rebelclip")
        elseif p ~= leader and has then p:StripWeapon("weapon_lc_rebelclip") end
    end
end
if timer and timer.Create then timer.Create("LivingCityRebelClip", 5, 0, function() LC.RebelClipTick() end) end

------------------------------------------------------------------------
-- Kind options in the chair (sv_livingcity_chair.lua calls this for what it doesn't know). s: the chair's session.
------------------------------------------------------------------------

function LC.RebelChairExtra(ply, s, what)
    if not On() then return nil end
    local npc, st = s.npc, s.st
    local p = npc.lcProfile
    local now = CurTime()
    if what == "talk" then
        if (s.talkNext or 0) > now then return "Give them a moment." end
        s.talkNext = now + 15
        local t = (p and LC.Psy and LC.Psy.Traits and LC.Psy.Traits(p)) or {}
        if (t.pride or 0) > 0.4 then return "They look past you. Kind words are wasted on this one." end
        local chance = math.Clamp(0.35 - 0.3 * (t.brave or 0) + 0.2 * (s.kind or 0) - 0.1 * (s.hits or 0), 0.1, 0.9)
        if Roll() < chance then
            s.resolve = math.max(0, (s.resolve or 2) - 1)
            return "You talk. No threats. Something in their shoulders comes down." .. (s.resolve <= 0 and " They're ready to answer." or "")
        end
        return "You talk. They listen, and give you nothing yet."
    elseif what == "food" then
        if s.fed then return "They've had what you gave them." end
        local have = LC.ItemsWhere and LC.ItemsWhere(ply, function(it) return (it.hunger or 0) > 0 or (it.thirst or 0) > 0 end) or {}
        local id = next(have)
        if not id then return "You've nothing to give them." end
        LC.TakeItem(ply, id, 1)
        s.fed, s.kind = true, (s.kind or 0) + 1
        s.resolve = math.max(0, (s.resolve or 2) - 1)
        if LC.Remember then LC.Remember(npc, ply, 3) end
        return "They take it like someone who has had nothing today. 'Thank you.' It costs them to say it."
    elseif what == "recruit" then
        if s.asked then return "You've had their answer." end
        s.asked = true
        if st.rebel then return "'I was always with you. You could have just asked.'" end
        local chance = math.Clamp(0.15 + 0.2 * (s.kind or 0) - 0.12 * (s.hits or 0), 0.02, 0.8)
        if Roll() >= chance then return "'I just want to go home.' Not this one. Not today." end
        st.rebel = true
        if p then p.rebel = true end
        if st.profile then st.profile.rebel = true end
        npc:SetNW2Bool("lc_prebel", true)
        -- (a recruited loyalist is a risk: now and then they are feeding Civil Protection)
        st.lcPlant = (s.hits or 0) > 0 and Roll() < 0.25 or nil
        local key, id = Key(ply), p and p.id
        if key and id and LC.ChronicleAdd then LC.ChronicleAdd({ k = "recruited", s = key, o = id, pred = "talked " .. NameOf(npc) .. " round in the chair", pos = npc:GetPos(), w = 2 }) end
        return "They look at the lamp, then at you. 'What would I have to do?' One of ours now. Probably."
    end
    return nil
end

------------------------------------------------------------------------
-- Executions
------------------------------------------------------------------------

-- Is this one in the Resistance's hands (the cage or the chair)?
function LC.RebelHolds(target)
    if not IsValid(target) then return false end
    if target:IsPlayer() then
        return (LC.RebelHeldPly and LC.RebelHeldPly[target] ~= nil) or (LC.ChairPlayerOf and LC.ChairPlayerOf(target) ~= nil)
    end
    return (LC.RebelHeld and LC.RebelHeld[target] ~= nil) or (LC.ChairHas and LC.ChairHas(target)) or false
end

function LC.ExecHasLeave(by, target)
    local l = LC.ExecLeave[target]
    return l ~= nil and l.untilT > CurTime() and (l.by == nil or l.by == by)
end

-- officer: who answers (nil: the cell's own, by its rules).
function LC.ExecAnswer(officer, by, yes)
    local ask = LC.ExecAsks[by]
    if not ask then return false end
    LC.ExecAsks[by] = nil
    if not IsValid(by) or not IsValid(ask.target) then return false end
    if yes then
        LC.ExecLeave[ask.target] = { by = by, untilT = CurTime() + LEAVE_SECS }
        by:SetNW2Entity("lc_exec_leave", ask.target)
        by:ChatPrint("[Miscount] " .. (IsValid(officer) and (officer:Nick() .. " looks at the prisoner, then at you. 'Do it.'") or "The word comes back from the cell: 'Do it.'"))
    else
        by.lcExecRefused = ask.target
        by:ChatPrint("[Miscount] " .. (IsValid(officer) and (officer:Nick() .. " shakes their head. 'No. Not that.'") or "The word comes back from the cell: 'No. They walk.'"))
    end
    hook.Run("LivingCityExecAnswered", by, ask.target, yes, officer)
    return true
end

function LC.ExecAskLeave(by, target)
    if not On() or not (LC.RebelMayHold and LC.RebelMayHold(by)) or not LC.RebelHolds(target) then return nil end
    if LC.RebelMayOrder(by) then return "You don't need anyone's leave." end
    if LC.ExecHasLeave(by, target) then return "You have leave already." end
    local officers = {}
    for _, p in ipairs(player.GetAll()) do if p ~= by and LC.RebelMayOrder(p) then officers[#officers + 1] = p end end
    LC.ExecAsks[by] = { target = target, at = CurTime(), officers = #officers }
    if #officers > 0 then
        net.Start("lc_exec_ask")
        net.WriteEntity(by)
        net.WriteString(by:Nick())
        net.WriteString(NameOf(target))
        net.Send(officers)
    end
    return "You ask leave to execute " .. NameOf(target) .. ". Wait for the word."
end

net.Receive("lc_exec_answer", function(_, ply)
    local by, yes = net.ReadEntity(), net.ReadBool()
    if LC.RebelMayOrder(ply) and IsValid(by) then LC.ExecAnswer(ply, by, yes) end
end)

local Judge

-- The killing. by: a Resistance player. Returns what's said to them.
function LC.Execute(by, target)
    if not On() or not (LC.RebelMayHold and LC.RebelMayHold(by)) or not LC.RebelHolds(target) then return nil end
    local approved = LC.RebelMayOrder(by) or LC.ExecHasLeave(by, target)
    local name, pos, id, key = NameOf(target), target:GetPos(), IdOf(target), Key(by)
    local st = (not target:IsPlayer()) and LC.NPCs and LC.NPCs[target] or nil
    local refused = by.lcExecRefused == target
    LC.ExecLeave[target] = nil
    by.lcExecRefused = nil
    by:SetNW2Entity("lc_exec_leave", NULL)
    Scene(pos, by:Nick() .. " puts the barrel to " .. name .. "'s head. One shot.")
    target:EmitSound("weapons/pistol/pistol_fire2.wav", 90)
    if LC.ChronicleAdd and key then
        LC.ChronicleAdd({ k = "executed", s = key, o = id, pred = "executed " .. name .. (approved and "" or (refused and " after leave was refused" or " without leave")), pos = pos, w = 5 })
    end
    local final = true
    if target:IsPlayer() then
        -- a proper execution is the character's death; one without leave is an ordinary death two times in three
        final = approved or Roll() < (1 / 3)
        if LC.CageFreePlayer then LC.CageFreePlayer(target) end
        if LC.ChairPlayerEnd then LC.ChairPlayerEnd(target) end
        if final then
            target.lcEndOfLife = "executed"
            timer.Simple(5, function() if IsValid(target) then target.lcEndOfLife = nil end end)
        end
        target:Kill()
    else
        if st and st.rebel then LC.RebelAgainstRules(by, "sympathizer", name) end
        if LC.CageFree and LC.RebelHeld and LC.RebelHeld[target] then LC.CageFree(target) end
        if target.TakeDamage then target:TakeDamage(9999, by, by) end
        if IsValid(target) and target:Health() > 0 then target:SetHealth(0) end
    end
    LC.RebelAgainstRules(by, "execute", name)
    hook.Run("LivingCityExecuted", by, target, approved, final)
    if not approved then Judge(by, name, refused) end
    return approved and "It's done." or "It's done. Nobody gave you leave: someone will answer for that, and it will be you."
end

-- At the cage or the chair: "execute" (with leave, or a Lieutenant or above), "askleave", "execnoleave".
function LC.RebelExecDo(by, target, what)
    if not On() then return nil end
    if what == "askleave" then return LC.ExecAskLeave(by, target) end
    if what == "execute" then
        if not (LC.RebelMayOrder(by) or LC.ExecHasLeave(by, target)) then return "You'd need leave for that. Ask, or do it without." end
        return LC.Execute(by, target)
    end
    if what == "execnoleave" then return LC.Execute(by, target) end
    return nil
end

------------------------------------------------------------------------
-- Without leave: the highest-ranked member answers for the cell
------------------------------------------------------------------------

LC.ExecJudging = LC.ExecJudging or nil -- { killer, name, at, judge, refused }

Judge = function(killer, name, refused)
    local judge = LC.RebelChief(killer)
    if judge and Rank(judge) <= Rank(killer) and not LC.RebelMayOrder(judge) then judge = nil end
    LC.ExecJudging = { killer = killer, name = name, at = CurTime(), judge = judge, refused = refused }
    if judge then
        net.Start("lc_exec_judge")
        net.WriteString(killer:Nick())
        net.WriteString(name)
        net.WriteBool(refused and true or false)
        net.Send(judge)
    end
end

-- what: "expel", "demote", "execute", "stand". judge: a player, or nil (the cell's own).
function LC.ExecJudged(judge, what)
    local j = LC.ExecJudging
    if not j then return false end
    LC.ExecJudging = nil
    local killer = j.killer
    if not IsValid(killer) then return false end
    local key = Key(killer)
    local function Told(pred, w)
        if key and LC.ChronicleAdd then LC.ChronicleAdd({ k = "judged", s = key, pred = pred, pos = killer:GetPos(), w = w or 3 }) end
    end
    if what == "expel" then
        Told("was put out of the Resistance for killing " .. j.name, 4)
        killer:ChatPrint("[Miscount] 'You're done here. Don't come back.' You are nobody's now.")
        if LC.SetFaction then LC.SetFaction(killer, "citizen", nil, true) end
        if LC.ReportCrime then LC.ReportCrime(killer, "Known member of the Resistance", 300) end
    elseif what == "demote" then
        Told("was broken in rank for killing " .. j.name, 3)
        local idx = Rank(killer)
        local f = LCF and LCF.Get and LCF.Get("resistance")
        if f and f.ranks and f.ranks[idx - 1] then
            killer:SetPData("lcf_xp_resistance", f.ranks[idx - 1].xp or 0)
            if LC.AddXP then LC.AddXP(killer, 0, "broken in rank") end
        end
        killer:ChatPrint("[Miscount] 'You don't decide who dies.' They take your rank.")
    elseif what == "execute" then
        Told("is to be shot for killing " .. j.name, 4)
        LC.ExecLeave[killer] = { by = nil, untilT = CurTime() + 900 }
        killer:ChatPrint("[Miscount] The word is out: you are to be shot for it. Any of them may, once they have you.")
        if LC.RadioNotice then LC.RadioNotice("resistance", killer:Nick() .. " killed a prisoner without leave. Bring them in. The order is given.") end
    else
        what = "stand"
        Told("killed " .. j.name .. ", and the cell stood by it", 3)
        killer:ChatPrint("[Miscount] Nobody says a word about it. That is your answer.")
    end
    hook.Run("LivingCityExecJudged", killer, what, judge)
    return true, what
end

net.Receive("lc_exec_judged", function(_, ply)
    local what = net.ReadString()
    local j = LC.ExecJudging
    if j and j.judge == ply then LC.ExecJudged(ply, what) end
end)

-- With nobody to answer: the cell's own, by its rules and its mood.
function LC.RebelRuleTick(now)
    now = now or CurTime()
    for by, ask in pairs(LC.ExecAsks) do
        if not IsValid(by) or not IsValid(ask.target) then LC.ExecAsks[by] = nil
        elseif now - ask.at > (ask.officers > 0 and 45 or ASK_WAIT) then
            LC.ExecAnswer(nil, by, R.execute or LC.RebelAtmosphere() == "vengeful")
        end
    end
    local j = LC.ExecJudging
    if j and now - j.at > (IsValid(j.judge) and 90 or JUDGE_WAIT) then
        LC.ExecJudged(nil, (R.execute or LC.RebelAtmosphere() == "vengeful") and "stand" or "demote")
    end
end
if timer and timer.Create then timer.Create("LivingCityRebelRule", 2, 0, function() LC.RebelRuleTick(CurTime()) end) end

LC.TargetActions = LC.TargetActions or {}
LC.TargetActions.rebelrules = function(ply)
    if not LC.RebelClipSend(ply) then return false, "That's the Resistance's business." end
    return true
end
