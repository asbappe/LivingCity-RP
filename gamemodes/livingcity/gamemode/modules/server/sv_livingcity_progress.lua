--[[
    Living City: close calls, careers for life, and what passes on

    Death is serious, not a coin flip. Each person gets lc_close_calls (3)
    close calls: a death that isn't the end. You wake in the infirmary with
    what was in your pockets gone, still recovering for a while (20 less
    health for lc_close_call_recover minutes, 10), and you don't remember the
    fight or who started it (play it that way: no going back for revenge).
    A used close call comes back after lc_close_call_regen hours (3) of that
    person's life. The death after the last one is the end of them.

    Some deaths are the end whatever's left: a stalker's (death is the only
    way out), and stepping into the energizer. Retiring someone yourself
    (!characters, Retire) is an end too.

    Careers that can't be undone bind the person: once conditioned for the
    Overwatch, or made a stalker, they can't take up another faction. The way
    to be someone else is another character.

    Credits and XP belong to the person, never to the player. When a person
    ends, the next one gets lc_inherit_pct (25%) of their savings, up to
    lc_inherit_max (200): a relative's savings, not a fortune. Hoarding is
    taxed: every lc_levy_minutes (30) the Union takes lc_levy_pct (10%) of
    whatever anyone holds above lc_levy_threshold (2000) ("excess credits are
    redistributed").

    The player keeps only a record (their legacy): how many lives, the
    longest, and how the last few ended. It's shown on !characters.

    With permanent death off (lc_permadeath 0) nobody ends by dying, and close
    calls don't count down.
]]

if CLIENT then return end

LC = LC or {}

local FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
local cvCalls      = CreateConVar("lc_close_calls", "3", FLAGS, "Close calls each person gets: deaths that aren't the end (0: every death is final)")
local cvRegen      = CreateConVar("lc_close_call_regen", "3", FLAGS, "Hours of a person's life before a used close call comes back (0: never)")
local cvRecover    = CreateConVar("lc_close_call_recover", "10", FLAGS, "Minutes someone is still recovering after a close call (20 less health)")
local cvInheritPct = CreateConVar("lc_inherit_pct", "25", FLAGS, "Percent of a person's savings the next one inherits")
local cvInheritMax = CreateConVar("lc_inherit_max", "200", FLAGS, "Most credits the next person inherits")
local cvLevyAt     = CreateConVar("lc_levy_threshold", "2000", FLAGS, "Credits above which the Union takes a levy (0: no levy)")
local cvLevyPct    = CreateConVar("lc_levy_pct", "10", FLAGS, "Percent of the excess the levy takes each time")
local cvLevyEvery  = CreateConVar("lc_levy_minutes", "30", FLAGS, "Minutes between levies")

local RECOVER_HP = 20

local function Notice(ply, kind, title, text, secs)
    if LC.Notice then LC.Notice(ply, kind, title, text, secs) else ply:ChatPrint(title .. ": " .. text) end
end

------------------------------------------------------------------------
-- Close calls
------------------------------------------------------------------------

-- How many this person has left (a used one comes back with time lived).
function LC.CloseCallsLeft(ply)
    local max = cvCalls:GetInt()
    if max <= 0 then ply:SetNW2Int("lc_close_calls", 0) return 0 end
    local used = tonumber(ply:GetPData("lc_close_used", 0)) or 0
    local regen = cvRegen:GetFloat() * 3600
    if used > 0 and regen > 0 then
        local at = tonumber(ply:GetPData("lc_close_at", 0)) or 0
        local lived = LC.LivedSeconds and LC.LivedSeconds(ply) or 0
        local back = math.floor((lived - at) / regen)
        if back > 0 then
            used = math.max(0, used - back)
            ply:SetPData("lc_close_used", used)
            ply:SetPData("lc_close_at", at + back * regen)
        end
    end
    local left = math.max(0, max - used)
    ply:SetNW2Int("lc_close_calls", left)
    return left
end

-- Is this death the end of them? (Only asked with permanent death on.)
function LC.DeathIsFinal(ply)
    if ply.lcEndOfLife then return true end
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then return true end -- (the only way out)
    return LC.CloseCallsLeft(ply) <= 0
end

-- A close call: one fewer left, the pockets gone. The rest happens as they
-- get up again (PlayerSpawn below). How many are left now.
function LC.UseCloseCall(ply)
    local used = (tonumber(ply:GetPData("lc_close_used", 0)) or 0) + 1
    ply:SetPData("lc_close_used", used)
    ply:SetPData("lc_close_at", LC.LivedSeconds and LC.LivedSeconds(ply) or 0)
    if LC.Inventory and LC.TakeItem then
        for id, n in pairs(table.Copy(LC.Inventory(ply))) do LC.TakeItem(ply, id, n) end
    end
    ply.lcCloseCall = true
    local left = LC.CloseCallsLeft(ply)
    hook.Run("LivingCityCloseCall", ply, left)
    return left
end

hook.Add("PlayerSpawn", "LivingCityCloseCall", function(ply)
    if ply.lcCloseCall then
        ply.lcCloseCall = nil
        ply:SetNW2Float("lc_recovering_until", CurTime() + cvRecover:GetFloat() * 60)
        local left = LC.CloseCallsLeft(ply)
        timer.Simple(1.5, function()
            if not IsValid(ply) then return end
            Notice(ply, "bad", "A close call",
                "You wake up in the infirmary, sore and empty-handed: what was in your pockets is gone. You don't remember the fight, or who started it; leave it be. " ..
                (left > 0 and string.format("%d close call%s left.", left, left == 1 and "" or "s") or "That was the last one: the next death is the end of you."), 12)
        end)
    end
    -- still recovering: a little less to give (after the faction sets the body up)
    timer.Simple(0.2, function()
        if not IsValid(ply) or ply:GetNW2Float("lc_recovering_until", 0) <= CurTime() then return end
        ply:SetMaxHealth(math.max(30, ply:GetMaxHealth() - RECOVER_HP))
        ply:SetHealth(math.min(ply:Health(), ply:GetMaxHealth()))
    end)
end)

-- back to full strength when it wears off
timer.Create("LivingCityRecovering", 5, 0, function()
    local now = CurTime()
    for _, p in ipairs(player.GetAll()) do
        local t = p:GetNW2Float("lc_recovering_until", 0)
        if t > 0 and t <= now then
            p:SetNW2Float("lc_recovering_until", 0)
            if p:Alive() then p:SetMaxHealth(p:GetMaxHealth() + RECOVER_HP) end
        end
    end
end)

hook.Add("PlayerInitialSpawn", "LivingCityCloseCall", function(ply)
    timer.Simple(2, function() if IsValid(ply) then LC.CloseCallsLeft(ply) end end)
end)

------------------------------------------------------------------------
-- Careers for life
------------------------------------------------------------------------

-- Why this person can't take up another faction (nil if they can).
function LC.BoundTo(ply, fid)
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) and fid ~= "stalker" then
        return "Combine property doesn't choose. Only death ends a stalker."
    end
    if LC.Conditioned and LC.Conditioned(ply) and fid ~= "cp" then
        return "The conditioning can't be undone: this person is Overwatch for life. Another character (!characters) can be someone else."
    end
    return nil
end

------------------------------------------------------------------------
-- What passes on, and the player's legacy
------------------------------------------------------------------------

-- What the next person inherits from this one (called just before they end).
function LC.Inheritance(ply, why)
    if why == "admin" then return 0 end
    local old = LC.Credits and LC.Credits(ply) or 0
    return math.max(0, math.min(cvInheritMax:GetInt(), math.floor(old * cvInheritPct:GetFloat() / 100)))
end

function LC.Legacy(ply)
    local t = util.JSONToTable(ply:GetPData("lc_legacy", "") or "") or {}
    t.lives = tonumber(t.lives) or 0
    t.longest = tonumber(t.longest) or 0
    t.last = istable(t.last) and t.last or {}
    return t
end

local ENDS = { death = "died", energizer = "stepped into the light", retired = "retired", admin = "was taken out of the city by staff" }

-- The person ending now, written into the player's legacy.
function LC.RecordLegacy(ply, why)
    local t = LC.Legacy(ply)
    local lived = LC.LivedSeconds and LC.LivedSeconds(ply) or 0
    local name = LC.CharacterName and LC.CharacterName(ply) or ply:Nick()
    local f = LCF and LCF.Get and LCF.Get(ply:GetNW2String("lcf_faction", ""))
    local rank = f and f.ranks[ply:GetNW2Int("lcf_rank", 1)]
    t.lives = t.lives + 1
    if lived > t.longest then t.longest, t.longestName = lived, name end
    table.insert(t.last, 1, { name = name, lived = math.floor(lived), rank = rank and (rank.name .. ", " .. f.name) or nil, ended = ENDS[why] or why })
    while #t.last > 5 do table.remove(t.last) end
    ply:SetPData("lc_legacy", util.TableToJSON(t))
    return t
end

hook.Add("LivingCityNewCharacter", "LivingCityProgress", function(ply)
    ply:RemovePData("lc_close_used")
    ply:RemovePData("lc_close_at")
    ply:SetNW2Float("lc_recovering_until", 0)
    LC.CloseCallsLeft(ply)
    local n = ply.lcInherited or 0
    ply.lcInherited = nil
    if n > 0 then
        timer.Simple(4, function()
            if IsValid(ply) then Notice(ply, "info", "An inheritance", string.format("A relative you barely knew has left you %d credits. It isn't much. It's yours.", n), 8) end
        end)
    end
end)

------------------------------------------------------------------------
-- Retiring someone
------------------------------------------------------------------------

function LC.RetireCharacter(ply)
    if not IsValid(ply) or not ply:Alive() then return false, "Not while you're dead." end
    if LC.PlayerIsWanted and LC.PlayerIsWanted(ply) then return false, "Not while you're wanted." end
    if (LC.InCustody and LC.InCustody(ply)) or (LC.Prisoners and LC.Prisoners[ply]) then return false, "Not while you're in custody." end
    if LC.InCombat and LC.InCombat(ply) then return false, "Not in the middle of a fight." end
    if LC.PlayerIsStalker and LC.PlayerIsStalker(ply) then return false, "A stalker doesn't retire. There's only the one way out." end
    if not LC.NewCharacter then return false end
    local old = LC.CharacterName and LC.CharacterName(ply) or ply:Nick()
    LC.NewCharacter(ply, "retired")
    ply:Spawn()
    return true, old .. " has left the city for good. Somebody new takes their place."
end

------------------------------------------------------------------------
-- The Union levy on hoarded credits
------------------------------------------------------------------------

function LC.Levy(ply)
    local at = cvLevyAt:GetInt()
    if at <= 0 or not LC.Credits or not LC.AddCredits then return 0 end
    local have = LC.Credits(ply)
    if have <= at then return 0 end
    local take = math.floor((have - at) * cvLevyPct:GetFloat() / 100)
    if take <= 0 then return 0 end
    LC.AddCredits(ply, -take)
    Notice(ply, "info", "Union levy", string.format("%d credits redistributed: holdings above %d are shared with the Union. Spend it, or lose it slowly.", take, at), 8)
    return take
end

local nextLevy
timer.Create("LivingCityLevy", 30, 0, function()
    local now = CurTime()
    local every = math.max(1, cvLevyEvery:GetFloat()) * 60
    if not nextLevy then nextLevy = now + every return end -- (not the moment the server starts)
    if now < nextLevy then return end
    nextLevy = now + every
    for _, p in ipairs(player.GetAll()) do LC.Levy(p) end
end)
