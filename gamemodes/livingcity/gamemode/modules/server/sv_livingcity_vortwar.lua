--[[
    Living City: vortigaunt dream warfare (sv_livingcity_vortwar.lua)

    The owner, 8 November: freed vortigaunts "can appear in their purple skinned form ... and alter
    the dream to make the combine and administrator look bad ... a sort of psychosis dream warfare
    thing"; "The more vortigaunts freed and still alive, the more influence they have on dreams".
    Built 9 November with the owner's answers: 15% a vortigaunt, at most 60%; you side with them by
    standing in their light; siding costs Civil Standing but the Resistance hears of it; if they win,
    her figure shatters.

    Influence (LC.VortWarInfluence): the freed vortigaunts alive, Free Vortigaunt players (awake or
    asleep) and the city's vortigaunts cut loose from their shackles (e.lcVortFreed). Shown on her
    tablet. Each propaganda dream rolls LC.VortWarPer (15%) for each, at most LC.VortWarMost (60%),
    that they break in, a quarter to nearly half way through (LC.VortWarAt):
      - purple vortigaunts appear about the dream, each in a circle of purple light; the screen
        turns purple; her figure flickers into raw flesh; her soldiers falter; their voices answer
        hers;
      - a tug-of-war (LC.VortWarPull): every dreamer standing in their light pulls toward the
        vortigaunts, every one outside it (at her task) toward her; LC.VortWarSecs at most;
      - they win: her figure cracks and falls apart in purple light, the dream ends for everyone,
        and her next propaganda dream's offences cost half (the spell is weakened);
      - she wins: "Begone!", they fade, and the dream carries on.
    As they wake, a dreamer who was more in the light than out of it sided with them: -5 Civil
    Standing (LC.VortWarCost), but the Resistance hears of it (a Resistance member: XP and trust;
    anyone else: sympathy, and trust toward joining). One who kept out of it: +5 (LC.VortWarLoyal).
    The editor's "Dreams: test one" has a button to make the next propaganda dream's break-in sure.
]]

if CLIENT then return end

LC = LC or {}

local K, P = LC.DreamGameKit, LC.PropagandaKit
if not K or not P or not LC.DreamGameStart then return end
local Actor, Snd, Done, InPlay = K.Actor, K.Snd, K.Done, K.InPlay
local Line, Everyone, Notice = P.Line, P.Everyone, P.Notice

LC.VortWarPer, LC.VortWarMost = 0.15, 0.60
LC.VortWarAt = { 0.25, 0.45 }      -- (when they break in: this far through the dream)
LC.VortWarSecs = 45                -- (the longest the tug-of-war lasts)
LC.VortWarLead = 8                 -- (from their appearing to the tug-of-war: the owner, 12 November, "can the delay be like 8 seconds?")
LC.VortWarSound = "ambient/energy/whiteflash.wav" -- (their arrival: once, not a loop; the charge sound looped and outlived the dream)
LC.VortWarPull = 1 / 18            -- (the meter, a second, with every dreamer on one side)
LC.VortWarRadius = 120             -- (their light)
LC.VortWarCost, LC.VortWarLoyal, LC.VortWarXP = 5, 5, 10
local PURPLE = Color(175, 90, 255)

local LINES = {
    vortwar_in = { "A Vortigaunt", "The Vortessence sees through her false light. Come, stand with us, and see what is true." },
    vortwar_answer1 = { "A Vortigaunt", "She says she protects you. Ask who built the walls." },
    vortwar_answer2 = { "A Vortigaunt", "Her smile is painted on. Look closer." },
    vortwar_answer3 = { "A Vortigaunt", "We were chained as you are chained. We are free. You can be." },
    vortwar_answer4 = { "A Vortigaunt", "The dream is hers. The waking is yours." },
    vortwar_loyal = { "The Administrator", "Begone, false spirits! These citizens are MINE." },
    vortwar_shatter = { "A Vortigaunt", "Her light was never yours. Wake, and see." },
}
LC.PropagandaCueWho = LC.PropagandaCueWho or {}
for k, v in pairs(LINES) do LC.PropagandaCues[k], LC.PropagandaCueWho[k] = v[2], v[1] end
LC.VortWarAnswers = { "vortwar_answer1", "vortwar_answer2", "vortwar_answer3", "vortwar_answer4" }

local SIDE = {} -- [steamid64] = "vort" or "loyal": how they wake
local function Key(p) return tostring(p:SteamID64()) end
function LC.VortWarSide(p) return IsValid(p) and SIDE[Key(p)] or nil end
local function SayAs(g, cue)
    local snd, text = LC.PropagandaVoice(cue)
    g.said = g.said or {}
    g.said[#g.said + 1] = cue
    Line(g, text, snd, LC.PropagandaCueWho[cue])
end

-- The freed vortigaunts alive.
function LC.VortWarInfluence()
    local n = 0
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:GetNW2String("lcf_faction", "") == "resistance" and p:GetNW2String("lcf_special", "") == "vortigaunt" then n = n + 1 end
    end
    for _, e in ipairs(ents.FindByClass and ents.FindByClass("npc_vortigaunt") or {}) do
        if IsValid(e) and e.lcVortFreed and (not e.Health or e:Health() > 0) then n = n + 1 end
    end
    return n
end
function LC.VortWarChance(n)
    n = n or LC.VortWarInfluence()
    return math.min(LC.VortWarMost, LC.VortWarPer * n)
end
-- For her tablet.
function LC.VortWarLine()
    local n = LC.VortWarInfluence()
    if n <= 0 then return nil end
    return string.format("Freed vortigaunts alive: %d. They may break into %d%% of your propaganda dreams.", n, math.floor(LC.VortWarChance(n) * 100 + 0.5))
end

-- Inside the dream's floor, somewhere.
local function Spots(g, n)
    local b = g.bounds
    local c = g.dream.pos
    local z = g.top or (c.z + 2)
    local out = {}
    for i = 1, n do
        local a = (i - 0.5) / n * math.pi * 2 + math.Rand(-0.3, 0.3)
        local rx = b and (b.maxs.x - b.mins.x) * 0.3 or 300
        local ry = b and (b.maxs.y - b.mins.y) * 0.3 or 300
        local cx = b and (b.mins.x + b.maxs.x) / 2 or c.x
        local cy = b and (b.mins.y + b.maxs.y) / 2 or c.y
        out[#out + 1] = Vector(cx + math.cos(a) * rx, cy + math.sin(a) * ry, z)
    end
    return out
end

-- A propaganda dream begins: will they come, and when.
function LC.VortWarSetup(g)
    if not g or not LC.PropagandaDreams[g.id] then return false end
    local weak = LC.VortWeakNext
    LC.VortWeakNext = nil
    for p in pairs(g.pl) do if IsValid(p) then p.lcVortWeak = weak or nil end end -- (her spell weakened: offences cost half)
    if weak then for _, p in ipairs(Everyone(g)) do Notice(p, "info", "Something is off", "Her light seems thinner tonight, as if something cracked it.", 6) end end
    local force = LC.VortWarForceNext
    LC.VortWarForceNext = nil
    if not force and math.random() >= LC.VortWarChance() then return false end
    local secs = g.def.secs or 120
    local at = math.Clamp(secs * math.Rand(LC.VortWarAt[1], LC.VortWarAt[2]), math.min(15, secs * 0.3), math.max(10, secs - 40))
    g.vw = { phase = "wait", at = g.t0 + at, meter = 0, side = {} }
    -- what the dreamers' screens are told, on top of the dream's own
    local base = g.def
    g.def = setmetatable({ state = function(gg, p)
        local t = base.state(gg, p) or {}
        local vw = gg.vw
        if vw and vw.phase == "gather" then
            local spots = {}
            for _, v in ipairs(vw.vorts or {}) do spots[#spots + 1] = { v.at.x, v.at.y, v.at.z } end
            t.vw = false
            t.vwSpots = spots
            t.big = string.format("The vortigaunts are gathering their power. In %d seconds: stand in their light, or keep to her.", math.max(1, math.ceil((vw.tugAt or 0) - CurTime())))
        elseif vw and vw.phase == "tug" then
            local spots = {}
            for _, v in ipairs(vw.vorts) do spots[#spots + 1] = { v.at.x, v.at.y, v.at.z } end
            t.vw = { meter = vw.meter, light = vw.side[p] and vw.side[p].now or false, spots = spots, r = LC.VortWarRadius }
            t.big = (vw.side[p] and vw.side[p].now) and "You stand in the vortigaunts' light." or "The vortigaunts are here. Stand in their light, or keep to her."
        else
            t.vw = false
        end
        return t
    end }, { __index = base })
    return true
end

local orig = LC.DreamGameStart
function LC.DreamGameStart(dream)
    local ok, why = orig(dream)
    if ok and dream and dream.game then
        local fine, err = LC.Try(LC.VortWarSetup, dream.game)
        if not fine and LC.Error then LC.Error("vortigaunt dream warfare", err) end
    end
    return ok, why
end

-- Her figure in the dream: the giant one, or herself when she's starring.
local function HerFig(g) return (IsValid(g.her) and g.her) or (IsValid(g.star) and g.star) or nil end

local function BreakIn(g, now)
    local vw = g.vw
    local n = math.Clamp(LC.VortWarInfluence(), 2, 4)
    vw.vorts = {}
    for _, at in ipairs(Spots(g, n)) do
        local c = g.dream.pos
        local e = Actor(g, "models/vortigaunt.mdl", at, math.deg(math.atan2(c.y - at.y, c.x - at.x)), 1.2, ACT_IDLE or 1)
        if e then
            e:SetColor(PURPLE)
            vw.vorts[#vw.vorts + 1] = { e = e, at = at }
        end
    end
    if vw.vorts[1] then Snd(vw.vorts[1].e, LC.VortWarSound, 75) end
    -- her figure: there to flicker (a giant one if this dream has none)
    if not IsValid(g.her) and not IsValid(g.star) and LC.AdmireModel then
        local b = g.bounds
        local at = b and Vector(b.maxs.x - 120, (b.mins.y + b.maxs.y) / 2, (g.top or g.dream.pos.z) + 120) or (g.dream.pos + Vector(0, 0, 120))
        g.her = Actor(g, LC.AdmireModel(), at, 180, 2.5, ACT_IDLE or 1)
        vw.ownHer = true
    end
    local fig = HerFig(g)
    vw.herMat = fig and fig.GetMaterial and fig:GetMaterial() or ""
    -- her soldiers falter
    for _, e in ipairs(g.ents) do
        local m = IsValid(e) and e.GetModel and string.lower(e:GetModel() or "") or ""
        if string.find(m, "combine_soldier", 1, true) or string.find(m, "police", 1, true) then
            if K.Animate then K.Animate(e, ACT_COWER or ACT_IDLE or 1) end
            e:SetAngles(e:GetAngles() + Angle(0, math.random(-40, 40), 0))
        end
    end
    -- (a short gathering, then the tug-of-war: LC.VortWarLead)
    vw.phase, vw.tugAt = "gather", now + LC.VortWarLead
    SayAs(g, "vortwar_in")
    for _, p in ipairs(Everyone(g)) do
        if p.ScreenFade then p:ScreenFade(SCREENFADE and SCREENFADE.IN or 1, Color(150, 60, 255, 170), 2, 0.3) end
        Notice(p, "warn", "The vortigaunts are here", string.format("Purple vortigaunts have broken into the dream. In %d seconds, stand in their light to side with them (it costs Civil Standing, but the Resistance will hear of it), or keep to her task and stay loyal.", LC.VortWarLead), 10)
    end
    g.dirty = true
end
LC.VortWarBreakIn = BreakIn

-- Who sided with whom (more in the light than out of it), for how they wake.
local function Settle(g)
    for p, s in pairs(g.vw.side) do
        if IsValid(p) then SIDE[Key(p)] = (s.inT or 0) > (s.outT or 0) and "vort" or "loyal" end
    end
end

local function Fade(g)
    local vw = g.vw
    Settle(g)
    vw.phase = "gone"
    SayAs(g, "vortwar_loyal")
    for _, v in ipairs(vw.vorts or {}) do if IsValid(v.e) then if K.Puff then K.Puff(v.at) end v.e:Remove() end end
    local fig = HerFig(g)
    if fig and fig.SetMaterial then fig:SetMaterial(vw.herMat or "") end
    if vw.ownHer and IsValid(g.her) then g.her:Remove() g.her = nil end
    g.dirty = true
end

local function Shatter(g)
    local vw = g.vw
    Settle(g)
    vw.phase, vw.won = "shattered", true
    SayAs(g, "vortwar_shatter")
    LC.VortWeakNext = true -- (her next propaganda dream: offences cost half)
    local fig = HerFig(g)
    if fig then
        local pos = fig:GetPos() + Vector(0, 0, 60 * (fig.GetModelScale and fig:GetModelScale() or 1))
        if EffectData then
            for i = 0, 5 do
                local ed = EffectData()
                ed:SetOrigin(pos + Vector(math.Rand(-80, 80), math.Rand(-80, 80), math.Rand(-120, 120)))
                util.Effect("cball_explode", ed, true, true)
            end
        end
        Snd(fig, "physics/glass/glass_largesheet_break" .. math.random(1, 3) .. ".wav", 120)
        if fig == g.her then g.her:Remove() g.her = nil
        elseif fig.SetMaterial then fig:SetMaterial(vw.herMat or "") end -- (the star herself: she wakes with the rest)
    end
    for _, p in ipairs(InPlay(g)) do
        Done(g, p, "time", "The spell breaks", "Her figure cracks and falls apart in purple light. The dream lets go of you.")
    end
    g.dirty = true
end

local function Tick(g, dt, now)
    local vw = g.vw
    if vw.phase == "wait" then
        if now >= vw.at then BreakIn(g, now) end
        return
    end
    if vw.phase == "gather" then
        if now >= (vw.tugAt or 0) then
            vw.phase, vw.since, vw.answerAt, g.dirty = "tug", now, now + 8, true
        elseif now >= (vw.sentAt or 0) then vw.sentAt, g.dirty = now + 1, true end -- (the countdown on their screens)
        return
    end
    if vw.phase ~= "tug" then return end
    -- her figure flickers into raw flesh
    local fig = HerFig(g)
    if fig and fig.SetMaterial and now >= (vw.flickAt or 0) then
        vw.flick = not vw.flick
        vw.flickAt = now + (vw.flick and 0.25 or math.Rand(0.6, 1.4))
        fig:SetMaterial(vw.flick and "models/flesh" or (vw.herMat or ""))
    end
    if now >= vw.answerAt then
        vw.answerAt = now + math.Rand(8, 11)
        SayAs(g, LC.VortWarAnswers[math.random(#LC.VortWarAnswers)])
    end
    local players = InPlay(g)
    local r2 = LC.VortWarRadius * LC.VortWarRadius
    local inN = 0
    for _, p in ipairs(players) do
        local s = vw.side[p] or {}
        vw.side[p] = s
        local pos, lit = p:GetPos(), false
        for _, v in ipairs(vw.vorts) do
            if (pos.x - v.at.x) ^ 2 + (pos.y - v.at.y) ^ 2 < r2 and math.abs(pos.z - v.at.z) < 120 then lit = true break end
        end
        if lit ~= s.now then g.dirty = true end
        s.now = lit
        if lit then s.inT, inN = (s.inT or 0) + dt, inN + 1 else s.outT = (s.outT or 0) + dt end
    end
    local n = #players
    if n > 0 then vw.meter = math.Clamp(vw.meter + dt * LC.VortWarPull * (inN - (n - inN)) / n, -1, 1) end
    if now >= (vw.sentAt or 0) then vw.sentAt, g.dirty = now + 0.25, true end
    if vw.meter >= 0.999 then Shatter(g)
    elseif vw.meter <= -0.999 then Fade(g)
    elseif now >= vw.since + LC.VortWarSecs then
        if vw.meter > 0 then Shatter(g) else Fade(g) end
    end
end
LC.VortWarTick = Tick

timer.Create("LivingCityVortWar", 0.1, 0, function()
    local dream = LC.DreamActive
    local g = dream and dream.game
    if not g or g.stopped or not g.vw then return end
    local now = CurTime()
    local dt = math.Clamp(now - (g.vw.last or now), 0, 0.25)
    g.vw.last = now
    local ok, err = LC.Try(Tick, g, dt, now)
    if not ok and LC.Error then LC.Error("vortigaunt dream warfare", err) end
end)

-- As they wake: who they sided with.
hook.Add("LivingCityDreamWoke", "LivingCityVortWar", function(p, _, why)
    if not IsValid(p) then return end
    local side = SIDE[Key(p)]
    SIDE[Key(p)] = nil
    if not side or why == "test" then return end -- (a test from the editor costs and earns nothing)
    if side == "vort" then
        if LC.AddStanding then LC.AddStanding(p, -LC.VortWarCost, "sided with the vortigaunts in a dream") end
        local res = p:GetNW2String("lcf_faction", "") == "resistance"
        if res and LC.AddXP then LC.AddXP(p, LC.VortWarXP, "sided with the vortigaunts in a dream") end
        if not res and LC.AddTrait then LC.AddTrait(p, "sympathy", 1) end
        if LC.Bump then LC.Bump(p, "res_jobs", 1) end -- (the Resistance trusts you a little more)
        Notice(p, "warn", "You stood in their light", string.format("You wake with purple at the edges of your sight. The city noticed: -%d Civil Standing. The Resistance noticed too%s.",
            LC.VortWarCost, res and string.format(" (+%d XP)", LC.VortWarXP) or ", and they'll remember it"), 10)
    else
        if LC.AddStanding then LC.AddStanding(p, LC.VortWarLoyal, "stayed loyal when the vortigaunts broke into a dream") end
        Notice(p, "info", "You kept to her", string.format("The vortigaunts called, and you didn't listen: +%d Civil Standing.", LC.VortWarLoyal), 8)
    end
end)

concommand.Add("lc_vortwar_next", function(ply)
    if IsValid(ply) and not (LC.CanEdit and LC.CanEdit(ply) or ply:IsSuperAdmin()) then return end
    LC.VortWarForceNext = true
    local text = "The next propaganda dream (a test from the editor too): the vortigaunts break in for sure."
    if IsValid(ply) and LC.Notice then LC.Notice(ply, "info", "Vortigaunts", text, 8) elseif LC.Log then LC.Log("info", text) end
end)
