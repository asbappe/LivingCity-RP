--[[
    Living City: Enforcers in the dreams

    The owner, 8 November: "the metrocops can be the enforcers and in dream
    they can punish bad dreamers! then they have something to do, can see the
    dreams and partake but not be dinged like citizens and rebels", and
    "happy dreams or neutral dreams don't need enforcers and they can just
    join the dream as the rest of the players do". XP: "1 per correct
    punishment".

    Who: Civil Protection (Overwatch too) and the Administration, asleep when
    a dream comes. In a Happy or Neutral dream they dream it like anyone. In
    a dream nobody can opt out of (a Nightmare, or a propaganda dream) they
    are Enforcers instead:

      - nothing in it can touch them: no lives, nothing lost, nothing won,
        no loyalty points, no health off for losing; and they can wake
        whenever they like (C > Settings > Shared dreams: wake up);
      - they never count towards the dream's dreamers (lc_dream_min), and a
        dream with only Enforcers asleep for it doesn't happen;
      - in an ending (The Flood, They Return and the rest) they watch it,
        free to fly about inside it, as a dreamer who is out of it does;
      - in a dream you play they walk the arena with a stun baton.

    Bad dreamers glow red (for Enforcers to see, for 20 seconds): a dreamer
    who commits an offence in a propaganda dream (caught standing in her gaze,
    insults, thoughtcrime and the rest: the dream already counts these), who
    says something disloyal in a nightmare, or who stands about doing nothing
    for 20 seconds in a dream where running is the point (The Patrol Maze,
    The Barrel Tower, The Crumbling Floor). The dreamer is told an Enforcer
    can see them. An Enforcer's baton (attack, within reach) on a glowing
    dreamer costs that dreamer a life, as being caught does (in a propaganda
    dream, the usual loyalty points too), clears the glow, and earns the
    Enforcer 1 XP (lc_dream_enforcer_xp), paid when they wake (a dream puts
    everything back as it was, XP included). On anyone else, nothing happens
    but a reminder: only the glowing can be punished.

    The Administrator still stars in a propaganda dream herself (her tablet's
    "Star in propaganda dreams yourself"); with that off, she's an Enforcer
    like the rest.

      lc_dream_enforcer_xp (1)
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvXP = CreateConVar("lc_dream_enforcer_xp", "1", FLAGS, "XP an Enforcer earns for each dreamer rightly punished in a dream (paid when they wake)")

local MARK_SECS, IDLE_SECS, IDLE_DIST, REACH = 20, 20, 48, 110
LC.DreamEnforcerMarkSecs = MARK_SECS
-- Dreams where standing about is shirking (in the rest, standing still can be the point: Freeze, Citizen, kneeling).
LC.DreamIdleGames = { maze = true, barrels = true, crumble = true }

local function Notice(p, kind, title, text, secs) if LC.Notice then LC.Notice(p, kind, title, text, secs) elseif p.ChatPrint then p:ChatPrint(title .. ": " .. text) end end

-- Would they be an Enforcer in this dream (id; tonight's when left out)? Civil Protection or the
-- Administration, in a dream nobody can opt out of.
function LC.DreamEnforcerRole(p, id)
    if not IsValid(p) or not p.GetNW2String then return false end
    id = id or (LC.DreamActive and LC.DreamActive.ending)
    if not id or not (LC.DreamForced and LC.DreamForced(id)) then return false end
    local f = p:GetNW2String("lcf_faction", "")
    return f == "cp" or f == "admin"
end

local GOAL = "You're an Enforcer. Nothing here can touch you. Dreamers who misbehave glow red: hit them with your baton (attack) to punish them. You can wake whenever you like."

-- Into a dream you play, as an Enforcer (sv_livingcity_dreamgames.lua calls this once the dreamers are placed).
function LC.DreamEnforcerJoin(g, p, hello)
    if not g or not IsValid(p) then return end
    g.enf = g.enf or {}
    g.enf[p] = { next = 0 }
    p.lcDreamEnforcer = g.dream.id
    p.lcDreamGame = g.def.id
    p.lcDreamEnforceXP = 0
    p:SetNW2Bool("lc_enforcer", true)
    -- among the dreamers, at one of their starts
    local starts = {}
    for _, s in pairs(g.pl) do if s.start then starts[#starts + 1] = s.start end end
    local at = #starts > 0 and (starts[math.random(#starts)] + Vector(math.Rand(-60, 60), math.Rand(-60, 60), 8)) or g.watchAt
    p:SetPos(at)
    g.enf[p].home = at
    if p.Give then p:Give("weapon_stunstick") end
    if p.SelectWeapon then p:SelectWeapon("weapon_stunstick") end
    local t = { k = "start", id = g.def.id, name = g.def.name, goal = GOAL, ends = g.ends, lives = 1, maxLives = 1, enforcer = true }
    for k, v in pairs(hello or {}) do if t[k] == nil then t[k] = v end end
    net.Start("lc_dreamgame") net.WriteTable(t) net.Send(p)
    Notice(p, "info", g.def.name .. ": you're an Enforcer", GOAL, 10)
end

function LC.DreamEnforcerLeave(p)
    if not IsValid(p) then return end
    p:SetNW2Bool("lc_enforcer", false)
end

-- An ending (not a dream you play): they watch it (sv_livingcity_dreams.lua calls this once it's begun).
function LC.DreamEndingEnforcers(dream)
    for _, p in ipairs(LC.DreamersOf and LC.DreamersOf(dream) or dream.list or {}) do
        if LC.DreamEnforcerRole(p, dream.ending) then
            p.lcDreamEnforcer = dream.id
            p.lcDreamEnforceXP = 0
            p:SetNW2Bool("lc_enforcer", true)
            if LC.EndingSpectator then LC.EndingSpectator(p, "You're an Enforcer in this nightmare: you watch over it, and nothing in it can touch you. Wake whenever you like.") end
        end
    end
end

------------------------------------------------------------------------
-- Bad dreamers
------------------------------------------------------------------------

local function Game()
    local dream = LC.DreamActive
    local g = dream and dream.game
    if g and not g.stopped then return g end
    return nil
end
local function HasEnforcers(g)
    for p in pairs(g.enf or {}) do if IsValid(p) and p.lcDreaming == g.dream.id then return true end end
    return false
end

function LC.DreamBad(p) return IsValid(p) and p:GetNW2Float("lc_dream_bad_until", 0) > CurTime() end

-- Mark a dreamer as misbehaving (why: what they did), for the Enforcers to see. True if marked.
function LC.DreamMarkBad(g, p, why)
    if not g or g.enfPunishing or not IsValid(p) then return false end
    local s = g.pl[p]
    if not s or s.done or not HasEnforcers(g) then return false end
    local fresh = not LC.DreamBad(p)
    p:SetNW2Float("lc_dream_bad_until", CurTime() + MARK_SECS)
    p.lcDreamBadWhy = why
    if fresh then
        Notice(p, "warn", "An Enforcer can see you", "You're glowing red (" .. why .. "). An Enforcer's baton would cost you a life. Behave.", 6)
        for q in pairs(g.enf) do
            if IsValid(q) then Notice(q, "info", "A bad dreamer", p:Nick() .. " is misbehaving (" .. why .. "). They glow red: punish them with your baton.", 5) end
        end
    end
    return true
end

hook.Add("LivingCityDreamOffence", "LivingCityDreamEnforcers", function(g, p, title)
    LC.DreamMarkBad(g, p, string.lower(tostring(title or "disloyalty")))
end)

-- Something disloyal said in a nightmare (a propaganda dream counts its own).
hook.Add("PlayerSay", "LivingCityDreamEnforcers", function(p, text)
    local g = Game()
    if not g or not g.pl[p] or (LC.PropagandaDreams and LC.PropagandaDreams[g.id]) then return end
    if LC.QuizForbidden and LC.QuizForbidden(text) then LC.DreamMarkBad(g, p, "saying something disloyal") end
end)

-- The baton: an attack within reach of a dreamer in front of them.
function LC.DreamEnforcerStrike(p)
    local g = Game()
    local e = g and g.enf and g.enf[p]
    if not e or p.lcDreaming ~= g.dream.id then return false end
    local now = CurTime()
    if now < (e.next or 0) then return false end
    e.next = now + 1
    local eye = p.EyePos and p:EyePos() or p:GetPos()
    local aim = p.GetAimVector and p:GetAimVector() or Vector(1, 0, 0)
    local best, bd
    for q, s in pairs(g.pl) do
        if IsValid(q) and not s.done and q.lcDreaming == g.dream.id then
            local to = q:GetPos() + Vector(0, 0, 40) - eye
            local d = to:Length()
            if d < REACH and (d < 30 or aim:Dot(to:GetNormalized()) > 0.5) and (not bd or d < bd) then best, bd = q, d end
        end
    end
    if not best then return false end
    if not LC.DreamBad(best) then
        Notice(p, "info", "Not them", best:Nick() .. " has done nothing wrong (yet). Only dreamers glowing red can be punished.", 4)
        return false
    end
    local why = best.lcDreamBadWhy or "misbehaving"
    g.enfPunishing = true
    local hit
    local ok, err = pcall(function()
        if LC.PropagandaDreams and LC.PropagandaDreams[g.id] and LC.PropagandaOffend then
            hit = LC.PropagandaOffend(g, best, "An Enforcer's baton", "An Enforcer caught you (" .. why .. ").")
        elseif LC.DreamGameHit then
            hit = LC.DreamGameHit(g, best, "An Enforcer's baton", "An Enforcer caught you (" .. why .. ").")
        end
    end)
    g.enfPunishing = nil
    if not ok and LC.Error then LC.Error("dream enforcers", err) end
    if not hit then return false end
    best:SetNW2Float("lc_dream_bad_until", 0)
    best.lcDreamBadWhy = nil
    if best.EmitSound then best:EmitSound("weapons/stunstick/stunstick_impact1.wav", 70) end
    local xp = math.max(0, cvXP:GetInt())
    p.lcDreamEnforceXP = (p.lcDreamEnforceXP or 0) + xp
    Notice(p, "info", "Punished", string.format("%s is punished.%s", best:Nick(), xp > 0 and string.format(" +%d XP when you wake.", xp) or ""), 4)
    return true
end
hook.Add("KeyPress", "LivingCityDreamEnforcers", function(p, key)
    if key == (IN_ATTACK or 1) and p.lcDreamEnforcer then LC.DreamEnforcerStrike(p) end
end)

-- Every half second: who's standing about, and the Enforcers kept inside the arena.
function LC.DreamEnforcersTick(now)
    local g = Game()
    if not g or not g.enf then return end
    local b = g.bounds
    for p, e in pairs(g.enf) do
        if IsValid(p) and p.lcDreaming == g.dream.id and b then
            local pos = p:GetPos()
            if pos.x < b.mins.x or pos.x > b.maxs.x or pos.y < b.mins.y or pos.y > b.maxs.y or pos.z < b.mins.z or pos.z > b.maxs.z then
                if e.home then p:SetPos(e.home) end
            end
        end
    end
    if not LC.DreamIdleGames[g.id] or not HasEnforcers(g) then return end
    g.idle = g.idle or {}
    for p, s in pairs(g.pl) do
        if IsValid(p) and not s.done and now >= (s.safe or 0) then
            local w = g.idle[p]
            local pos = p:GetPos()
            if not w or pos:Distance(w.pos) > IDLE_DIST then
                g.idle[p] = { pos = pos, t = now }
            elseif now - w.t >= IDLE_SECS then
                g.idle[p] = { pos = pos, t = now }
                LC.DreamMarkBad(g, p, "standing about doing nothing")
            end
        end
    end
end
timer.Create("LivingCityDreamEnforcers", 0.5, 0, function()
    local ok, err = pcall(LC.DreamEnforcersTick, CurTime())
    if not ok and LC.Error then LC.Error("dream enforcers", err) end
end)

-- Awake, with everything put back: now the XP they earned.
hook.Add("LivingCityDreamWoke", "LivingCityDreamEnforcers", function(p)
    if not IsValid(p) then return end
    p:SetNW2Float("lc_dream_bad_until", 0)
    p.lcDreamBadWhy = nil
    local xp = p.lcDreamEnforceXP or 0
    p.lcDreamEnforceXP = nil
    if p.lcDreamWokeEnforcer and xp > 0 and LC.AddXP then
        LC.AddXP(p, xp, "dream enforcement")
        Notice(p, "info", "Enforcement", string.format("For the dreamers you punished: +%d XP.", xp), 6)
    end
end)
